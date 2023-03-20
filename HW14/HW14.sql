USE master
ALTER DATABASE WideWorldImporters

SET ENABLE_BROKER; 

ALTER DATABASE WideWorldImporters SET TRUSTWORTHY ON;

ALTER AUTHORIZATION    
   ON DATABASE::WideWorldImporters TO [sa];

--создание контракта и типов сообщений

USE WideWorldImporters
-- For Request
CREATE MESSAGE TYPE
[//WWI/SB/RequestMessage]
VALIDATION=WELL_FORMED_XML;
-- For Reply
CREATE MESSAGE TYPE
[//WWI/SB/ReplyMessage]
VALIDATION=WELL_FORMED_XML; 

GO

CREATE CONTRACT [//WWI/SB/Contract]
      ([//WWI/SB/RequestMessage]
         SENT BY INITIATOR,
       [//WWI/SB/ReplyMessage]
         SENT BY TARGET
      );
GO

-- создание очередей
CREATE QUEUE TargetQueueWWI;

CREATE SERVICE [//WWI/SB/TargetService]
       ON QUEUE TargetQueueWWI
       ([//WWI/SB/Contract]);
GO


CREATE QUEUE InitiatorQueueWWI;

CREATE SERVICE [//WWI/SB/InitiatorService]
       ON QUEUE InitiatorQueueWWI
       ([//WWI/SB/Contract]);
GO
--создаем таблицу для обработки очереди 
CREATE TABLE sales.cust_orders_cnt
(
    customer_id INT,
    orders_cnt INT,
    date_start  date ,
    date_end  date
)
--процедура отправки сообщения
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create or Alter  PROCEDURE Sales.Send_Order
	@invoiceId INT
	,@date_start date
	,@date_end date
AS
BEGIN
	SET NOCOUNT ON;

    --Sending a Request Message to the Target	
	DECLARE @InitDlgHandle UNIQUEIDENTIFIER;
	DECLARE @RequestMessage NVARCHAR(4000);
	
	BEGIN TRAN 

	--Prepare the Message
	SELECT @RequestMessage = (SELECT InvoiceID,
								CustomerID,
								@date_start as date_start,
								@date_end as date_end
							  FROM Sales.Invoices AS Inv
							  WHERE InvoiceID = @invoiceId
							  FOR XML AUTO, root('RequestMessage')); 
	
	--Determine the Initiator Service, Target Service and the Contract 
	BEGIN DIALOG @InitDlgHandle
	FROM SERVICE
	[//WWI/SB/InitiatorService]
	TO SERVICE
	'//WWI/SB/TargetService'
	ON CONTRACT
	[//WWI/SB/Contract]
	WITH ENCRYPTION=OFF; 

	--Send the Message
	SEND ON CONVERSATION @InitDlgHandle 
	MESSAGE TYPE
	[//WWI/SB/RequestMessage]
	(@RequestMessage);
	COMMIT TRAN 
END
GO

--обработка очереди
CREATE PROCEDURE Sales.Get_Order
AS
BEGIN

	DECLARE @TargetDlgHandle UNIQUEIDENTIFIER,
			@Message NVARCHAR(4000),
			@MessageType Sysname,
			@ReplyMessage NVARCHAR(4000),
			@ReplyMessageName Sysname,
			@CustomerID INT,
			@date_start date,
			@date_end date,
			@xml XML; 
	
	BEGIN TRAN; 

	--Receive message from Initiator
	RECEIVE TOP(1)
		@TargetDlgHandle = Conversation_Handle,
		@Message = Message_Body,
		@MessageType = Message_Type_Name
	FROM dbo.TargetQueueWWI; 

	SELECT @Message;

	SET @xml = CAST(@Message AS XML);

	SELECT @CustomerID = R.Iv.value('@CustomerID','INT'),
		   @date_start = R.Iv.value('@date_start','DATE'),
		   @date_end = R.Iv.value('@date_end','DATE')
	FROM @xml.nodes('/RequestMessage/Inv') as R(Iv);

	IF EXISTS (select CustomerID  From Sales.Orders	where CustomerID = @CustomerID)
	BEGIN
		MERGE Sales.cust_orders_cnt AS target 
			USING (select 
						o.CustomerID
						,count (o.OrderID) as cnt_order
						,@date_start as date_start
						,@date_end as  date_end
					From Sales.Orders as o
					where o.CustomerID = @CustomerID
							and o.OrderDate between  @date_start and @date_end
					group by o.CustomerID
				) 
				AS source (CustomerID,cnt_order,date_start,date_end) 
				ON
				(target.customer_id = source.CustomerID) 
			WHEN MATCHED 
				THEN UPDATE SET customer_id = source.CustomerID,
								orders_cnt = source.cnt_order,
								date_start = source.date_start,
								date_end = source.date_end
			WHEN NOT MATCHED 
				THEN INSERT (customer_id,orders_cnt,date_start,date_end) 
					VALUES (source.CustomerID,source.cnt_order,source.date_start,source.date_end) 
			OUTPUT deleted.*, $action, inserted.*;
	END;
	
	SELECT @Message AS ReceivedRequestMessage, @MessageType; 
	
	-- Confirm and Send a reply
	IF @MessageType=N'//WWI/SB/RequestMessage'
	BEGIN
		SET @ReplyMessage =N'<ReplyMessage> Message received</ReplyMessage>'; 
	
		SEND ON CONVERSATION @TargetDlgHandle
		MESSAGE TYPE
		[//WWI/SB/ReplyMessage]
		(@ReplyMessage);
		END CONVERSATION @TargetDlgHandle;
	END 
	
	SELECT @ReplyMessage AS SentReplyMessage; 

	COMMIT TRAN;
END

--закрытие диалога

CREATE PROCEDURE Sales.ConfirmInvoice
AS
BEGIN
	--Receiving Reply Message from the Target.	
	DECLARE @InitiatorReplyDlgHandle UNIQUEIDENTIFIER,
			@ReplyReceivedMessage NVARCHAR(1000) 
	
	BEGIN TRAN; 

		RECEIVE TOP(1)
			@InitiatorReplyDlgHandle=Conversation_Handle
			,@ReplyReceivedMessage=Message_Body
		FROM dbo.InitiatorQueueWWI; 
		
		END CONVERSATION @InitiatorReplyDlgHandle; 
		
		SELECT @ReplyReceivedMessage AS ReceivedRepliedMessage; 

	COMMIT TRAN; 
END

--Настройки
USE [WideWorldImporters]
GO

ALTER QUEUE [dbo].[InitiatorQueueWWI] WITH STATUS = ON , RETENTION = OFF , POISON_MESSAGE_HANDLING (STATUS = OFF) 
	, ACTIVATION (   STATUS = on ,
        PROCEDURE_NAME = Sales.ConfirmInvoice, MAX_QUEUE_READERS = 1, EXECUTE AS OWNER) ; 

GO
ALTER QUEUE [dbo].[TargetQueueWWI] WITH STATUS = ON , RETENTION = OFF , POISON_MESSAGE_HANDLING (STATUS = OFF)
	, ACTIVATION (  STATUS = on ,
        PROCEDURE_NAME = Sales.Get_Order, MAX_QUEUE_READERS = 1, EXECUTE AS OWNER) ; 

GO

--вызовы процедур

SELECT *
FROM  Sales.cust_orders_cnt;

--Send message
EXEC Sales.Send_Order
	@invoiceId = 61236,
	@date_start = '2013-01-01',
	@date_end = '2014-01-01';

SELECT CAST(message_body AS XML),*
FROM dbo.TargetQueueWWI;

SELECT CAST(message_body AS XML),*
FROM dbo.InitiatorQueueWWI;

--Target
EXEC Sales.Get_Order;

--Initiator
EXEC Sales.ConfirmInvoice;
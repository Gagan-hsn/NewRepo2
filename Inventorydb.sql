-- Drop existing database if not in use
USE master;
GO
ALTER DATABASE inventorydb SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO
DROP DATABASE IF EXISTS inventorydb;
GO

-- Create fresh database
CREATE DATABASE inventorydb;
GO

USE inventorydb;
GO

-- Create Categories Table
CREATE TABLE Categories (
    CategoryID INT PRIMARY KEY,
    CategoryName VARCHAR(50)
);
GO

-- Create Products Table
CREATE TABLE Products (
    ProductID INT PRIMARY KEY,
    ProductName VARCHAR(50),
    CategoryID INT FOREIGN KEY REFERENCES Categories(CategoryID),
    Price DECIMAL(10,2),
    StockQuantity INT
);
GO

-- Create Customers Table
CREATE TABLE Customers (
    CustomerID INT PRIMARY KEY,
    CustomerName VARCHAR(50),
    Email VARCHAR(100),
    Phone VARCHAR(15)
);
GO

-- Create Orders Table
CREATE TABLE Orders (
    OrderID INT PRIMARY KEY,
    CustomerID INT FOREIGN KEY REFERENCES Customers(CustomerID),
    OrderDate DATE,
    TotalAmount DECIMAL(10,2)
);
GO

-- Create OrderDetails Table
CREATE TABLE OrderDetails (
    OrderDetailID INT PRIMARY KEY,
    OrderID INT FOREIGN KEY REFERENCES Orders(OrderID),
    ProductID INT FOREIGN KEY REFERENCES Products(ProductID),
    Quantity INT,
    UnitPrice DECIMAL(10,2)
);
GO

-- Insert data into Categories
INSERT INTO Categories (CategoryID, CategoryName) VALUES
(1, 'Laptops'),
(2, 'Smartphones'),
(3, 'Tablets'),
(4, 'Accessories');
GO

-- Insert data into Products
INSERT INTO Products (ProductID, ProductName, CategoryID, Price, StockQuantity) VALUES
(101, 'Dell XPS 13', 1, 999.99, 25),
(102, 'iPhone 14', 2, 1099.00, 15),
(103, 'Samsung Galaxy Tab S8', 3, 699.50, 8),
(104, 'Wireless Mouse', 4, 29.99, 50),
(105, 'USB-C Hub', 4, 45.00, 6);
GO

-- Insert data into Customers
INSERT INTO Customers (CustomerID, CustomerName, Email, Phone) VALUES
(201, 'Aman Verma', 'aman@example.com', '9876543210'),
(202, 'Sneha Sharma', 'sneha@example.com', '9876501234'),
(203, 'Ravi Kapoor', 'ravi@example.com', '9988776655');
GO

-- Insert data into Orders
INSERT INTO Orders (OrderID, CustomerID, OrderDate, TotalAmount) VALUES
(301, 201, '2025-07-01', 1129.99),
(302, 202, '2025-07-02', 1370.00),
(303, 203, '2025-07-03', 699.50);
GO

-- Insert data into OrderDetails
INSERT INTO OrderDetails (OrderDetailID, OrderID, ProductID, Quantity, UnitPrice) VALUES
(401, 301, 101, 1, 999.99),
(402, 301, 104, 1, 29.99),
(403, 302, 102, 1, 1099.00),
(404, 302, 105, 2, 45.00),
(405, 303, 103, 1, 699.50);
GO

-- Query: Total Sales per Category
SELECT c.CategoryName, SUM(od.Quantity * od.UnitPrice) AS TotalSales
FROM OrderDetails od
JOIN Products p ON od.ProductID = p.ProductID
JOIN Categories c ON p.CategoryID = c.CategoryID
GROUP BY c.CategoryName
ORDER BY TotalSales DESC;
GO

-- Stored Procedure: GetLowStockItems
CREATE PROCEDURE GetLowStockItems
AS
BEGIN
    SELECT ProductID, ProductName, StockQuantity
    FROM Products
    WHERE StockQuantity < 100;
END;
GO

-- Stored Procedure: GetOrderDetailsWithCustomer
CREATE PROCEDURE GetOrderDetailsWithCustomer
    @OrderID INT
AS
BEGIN
    SELECT o.OrderID, o.OrderDate, c.CustomerName, c.Email,
           od.Quantity, od.UnitPrice
    FROM Orders o
    JOIN Customers c ON c.CustomerID = o.CustomerID
    JOIN OrderDetails od ON od.OrderID = o.OrderID
    WHERE o.OrderID = @OrderID;
END;
GO

-- Stored Procedure: BulkUpdateStock
CREATE PROCEDURE BulkUpdateStock
    @ProductID INT,
    @Quantity INT
AS
BEGIN
    BEGIN TRANSACTION;

    BEGIN TRY
        IF EXISTS (SELECT 1 FROM Products WHERE ProductID = @ProductID)
        BEGIN
            UPDATE Products
            SET StockQuantity = StockQuantity - @Quantity
            WHERE ProductID = @ProductID;

            COMMIT;
        END
        ELSE
        BEGIN
            RAISERROR('Product not found.', 16, 1);
            ROLLBACK;
        END
    END TRY
    BEGIN CATCH
        ROLLBACK;
        THROW;
    END CATCH
END;
GO

-- Execute Procedures (Examples)
EXEC GetLowStockItems;
EXEC GetOrderDetailsWithCustomer 303;
EXEC BulkUpdateStock @ProductID = 101, @Quantity = 2;
GO

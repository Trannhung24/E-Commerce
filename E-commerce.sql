CREATE DATABASE E_COMMERCE;
GO

-- Bảng sản phẩm
CREATE TABLE Products (
    ProductID INT PRIMARY KEY,
    Name NVARCHAR(100),
    Description NTEXT,
    Price DECIMAL(10, 2),
    Stock INT
);

-- Bảng khách hàng
CREATE TABLE Customers (
    CustomerID INT PRIMARY KEY,
    Name NVARCHAR(100),
    Email VARCHAR(100),         -- Email không cần Unicode
    PasswordHash TEXT
);
GO

-- Bảng đơn hàng
CREATE TABLE Orders (
    OrderID INT PRIMARY KEY,
    CustomerID INT,
    OrderDate DATETIME,
    Status NVARCHAR(20),
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
);
GO

-- Chi tiết đơn hàng
CREATE TABLE OrderDetails (
    OrderDetailID INT PRIMARY KEY,
    OrderID INT,
    ProductID INT,
    Quantity INT,
    FOREIGN KEY (OrderID) REFERENCES Orders(OrderID),
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);
GO


INSERT INTO Products (ProductID, Name, Description, Price, Stock) VALUES
(1, N'Laptop ASUS', N'Laptop văn phòng cấu hình cao', 15000000, 20),
(2, N'Chuột Logitech', N'Chuột không dây', 500000, 100),
(3, N'Bàn phím cơ Razer', N'Bàn phím chơi game', 1800000, 50),
(4, N'Tai nghe Sony', N'Tai nghe Bluetooth', 2000000, 30),
(5, N'iPhone 15', N'Điện thoại Apple mới nhất', 25000000, 10),
(6, N'Ốp điện thoại', N'Ốp lưng silicon', 150000, 0);  -- Sản phẩm chưa được mua

INSERT INTO Customers (CustomerID, Name, Email, PasswordHash) VALUES
(1, N'Nguyễn Văn A', 'a@gmail.com', 'hash1'),
(2, N'Trần Thị B', 'b@gmail.com', 'hash2'),
(3, N'Lê Văn C', 'c@gmail.com', 'hash3');

INSERT INTO Orders (OrderID, CustomerID, OrderDate, Status) VALUES
(101, 1, '2025-03-20', N'Completed'),
(102, 2, '2025-04-05', N'Pending'),
(103, 1, '2025-04-10', N'Completed'),
(104, 3, '2025-04-11', N'Cancelled'),
(105, 2, '2025-04-11', N'Completed');

INSERT INTO OrderDetails (OrderDetailID, OrderID, ProductID, Quantity) VALUES
(1, 101, 1, 1),
(2, 101, 2, 2),
(3, 102, 5, 1),
(4, 103, 3, 1),
(5, 103, 4, 2),
(6, 105, 2, 1),
(7, 105, 3, 1);
-- 1.Tính tổng doanh thu từ mỗi khách hàng (chỉ tính đơn không bị hủy)
SELECT 
    C.CustomerID,
    C.Name AS CustomerName,
    SUM(P.Price * OD.Quantity) AS TotalRevenue
FROM Customers C
JOIN Orders O ON C.CustomerID = O.CustomerID
JOIN OrderDetails OD ON O.OrderID = OD.OrderID
JOIN Products P ON OD.ProductID = P.ProductID
WHERE O.Status != 'Canceled'  -- Loại đơn bị huỷ
GROUP BY C.CustomerID, C.Name;
-- 2. Tìm sản phẩm có số lượng bán cao nhất
SELECT TOP 5 
    P.ProductID,
    P.Name,
    SUM(OD.Quantity) AS TotalSold
FROM OrderDetails OD
JOIN Products P ON OD.ProductID = P.ProductID
GROUP BY P.ProductID, P.Name
ORDER BY TotalSold DESC;  -- Giảm dần: bán nhiều đứng đầu
--3. Đếm số đơn hàng mỗi ngày
SELECT 
    CONVERT(DATE, OrderDate) AS OrderDay,
    COUNT(*) AS TotalOrders
FROM Orders
GROUP BY CONVERT(DATE, OrderDate)
ORDER BY OrderDay;
-- 4. Tổng số lượng sản phẩm đã bán ra theo từng trạng thái đơn hàng
SELECT 
    O.Status,
    SUM(OD.Quantity) AS TotalQuantitySold
FROM Orders O
JOIN OrderDetails OD ON O.OrderID = OD.OrderID
GROUP BY O.Status;
--5. Tìm khách hàng chưa từng đặt đơn nào
SELECT 
    C.CustomerID,
    C.Name
FROM Customers C
LEFT JOIN Orders O ON C.CustomerID = O.CustomerID
WHERE O.OrderID IS NULL;

-- 6.Tính tổng số tiền cho từng đơn hàng
SELECT 
    O.OrderID,
    C.Name AS CustomerName,
    SUM(P.Price * OD.Quantity) AS TotalOrderAmount
FROM Orders O
JOIN Customers C ON O.CustomerID = C.CustomerID
JOIN OrderDetails OD ON O.OrderID = OD.OrderID
JOIN Products P ON OD.ProductID = P.ProductID
GROUP BY O.OrderID, C.Name;
-- 7.Danh sách sản phẩm gần hết hàng
SELECT 
    ProductID,
    Name,
    Stock
FROM Products
WHERE Stock < 10;
-- 8.Tổng doanh thu theo từng tháng
SELECT 
    FORMAT(OrderDate, 'yyyy-MM') AS Month,
    SUM(P.Price * OD.Quantity) AS MonthlyRevenue
FROM Orders O
JOIN OrderDetails OD ON O.OrderID = OD.OrderID
JOIN Products P ON OD.ProductID = P.ProductID
WHERE O.Status = 'Completed'  -- Chỉ tính đơn hoàn tất
GROUP BY FORMAT(OrderDate, 'yyyy-MM')
ORDER BY Month;
-- 9.Tìm khách hàng chi nhiều tiền nhất
SELECT TOP 1 
    C.CustomerID,
    C.Name,
    SUM(P.Price * OD.Quantity) AS TotalSpent
FROM Customers C
JOIN Orders O ON C.CustomerID = O.CustomerID
JOIN OrderDetails OD ON O.OrderID = OD.OrderID
JOIN Products P ON OD.ProductID = P.ProductID
WHERE O.Status = 'Completed'
GROUP BY C.CustomerID, C.Name
ORDER BY TotalSpent DESC;
--10. Danh sách sản phẩm chưa nằm trong bất kỳ đơn hàng nào
SELECT 
    P.ProductID,
    P.Name
FROM Products P
LEFT JOIN OrderDetails OD ON P.ProductID = OD.ProductID
WHERE OD.ProductID IS NULL;

--11. Dùng CTE và ROW_NUMBER để tìm đơn mới nhất mỗi khách
WITH RankedOrders AS (
    SELECT 
        O.OrderID,
        O.CustomerID,
        O.OrderDate,
        O.Status,
        ROW_NUMBER() OVER (PARTITION BY O.CustomerID ORDER BY O.OrderDate DESC) AS rn
    FROM Orders O
)
SELECT 
    R.CustomerID,
    C.Name,
    R.OrderID,
    R.OrderDate,
    R.Status
FROM RankedOrders R
JOIN Customers C ON R.CustomerID = C.CustomerID
WHERE R.rn = 1;
-- 12.Trung bình số lượng mỗi sản phẩm được đặt trong các đơn
SELECT 
    P.ProductID,
    P.Name,
    AVG(CAST(OD.Quantity AS FLOAT)) AS AvgQuantityPerOrder
FROM OrderDetails OD
JOIN Products P ON OD.ProductID = P.ProductID
GROUP BY P.ProductID, P.Name;
-- 13.Số lượng đơn theo từng trạng thái
SELECT 
    Status,
    COUNT(*) AS TotalOrders
FROM Orders
GROUP BY Status;
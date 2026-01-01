# Hướng dẫn chạy Challenge 1 đến Challenge 6 (Scaffold-ETH 2)

Tài liệu này hướng dẫn cách vận hành các Challenge phát triển ứng dụng phi
tập trung (DApp) trên môi trường máy tính cá nhân với Scaffold-ETH 2.

------------------------------------------------------------------------

## 1. Yêu cầu hệ thống

Trước khi bắt đầu, bạn cần cài đặt các công cụ sau:

-   **Node.js** phiên bản **v20 trở lên**
-   **Yarn** (v1 hoặc v2+)
-   **Git**

> Khuyến nghị kiểm tra phiên bản bằng các lệnh:
>
> ``` bash
> node -v
> yarn -v
> git --version
> ```

------------------------------------------------------------------------

## 2. Quy trình chạy chung (Áp dụng cho Challenge 1 đến Challenge 6)

### Bước 1: Di chuyển vào Challenge

Sử dụng lệnh `cd` để truy cập vào thư mục của Challenge bạn muốn chạy.

Ví dụ với **Challenge 6**:

``` bash
cd challenge-stablecoins
```

------------------------------------------------------------------------

### Bước 2: Cài đặt thư viện

Chạy lệnh sau để cài đặt các gói phụ thuộc:

``` bash
yarn install
```

------------------------------------------------------------------------

### Bước 3: Khởi chạy hệ thống (Sử dụng 3 cửa sổ Terminal)

Bạn cần mở **3 cửa sổ Terminal** và chạy song song các lệnh sau:

#### Terminal 1: Khởi chạy blockchain giả lập

``` bash
yarn chain
```

#### Terminal 2: Triển khai Smart Contract

``` bash
yarn deploy
```

#### Terminal 3: Khởi chạy giao diện người dùng (NextJS)

``` bash
yarn start
```

------------------------------------------------------------------------

### Bước 4: Truy cập ứng dụng

Mở trình duyệt và truy cập:

    http://localhost:3000

Bạn có thể bắt đầu tương tác với ứng dụng DApp tại đây.

------------------------------------------------------------------------

## 3. Danh sách thư mục các Challenge

  Challenge     Tên bài                       Tên thư mục
  ------- ----------------------------- -------------------------------------
  Challenge 1   Simple NFT                    `challenge-0-simple-nft`
  Challenge 2   Decentralized Staking         `challenge-1-decentralized-staking`
  Challenge 3   Token Vendor                  `challenge-2-token-vendor`
  Challenge 4   Dice Game                     `challenge-3-dice-game`
  Challenge 5   Over-collateralized Lending   `challenge-lending`
  Challenge 6   MyUSD Stablecoin              `challenge-stablecoins`

------------------------------------------------------------------------

## 4. Ghi chú

-   Luôn đảm bảo **Terminal 1 (yarn chain)** đang chạy trước khi deploy
    contract.
-   Nếu gặp lỗi, hãy thử:
    -   Xóa thư mục `node_modules`
    -   Chạy lại `yarn install`
-   Mỗi Lab có thể có smart contract và logic riêng, nhưng **quy trình
    chạy là giống nhau**.
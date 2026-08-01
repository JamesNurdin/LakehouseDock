/* goal: Analyze total sales and returns per customer per month across all sales channels, rank customers within each state, while filtering for the year 2000 non‑weekend monthly catalog pages, high coupon amounts, and excluding customers with returns on the same date. */
WITH joined_data AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        ca.ca_state,
        d.d_date,
        d.d_year,
        d.d_month_seq,
        cp.cp_department,
        cp.cp_type,
        ss.ss_net_paid AS ss_net_paid,
        cs.cs_net_paid AS cs_net_paid,
        ws.ws_net_paid AS ws_net_paid,
        wr.wr_net_loss AS wr_net_loss,
        ss.ss_coupon_amt,
        ss.ss_sold_date_sk,
        ws.ws_sold_date_sk,
        wr.wr_returned_date_sk,
        wr.wr_refunded_customer_sk
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
        AND wr.wr_returned_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2000
        AND d.d_weekend = 'N'
        AND cp.cp_type = 'monthly'
        AND ss.ss_coupon_amt > 100
        AND ws.ws_net_paid > 0
        AND NOT EXISTS (
            SELECT 1 FROM web_returns wr2
            WHERE wr2.wr_refunded_customer_sk = c.c_customer_sk
              AND wr2.wr_returned_date_sk = d.d_date_sk
        )
        AND ss.ss_net_paid > (
            SELECT AVG(ss2.ss_net_paid) FROM store_sales ss2
        )
),
per_customer_month AS (
    SELECT
        c_customer_sk,
        c_customer_id,
        ca_state,
        d_year,
        d_month_seq,
        SUM(ss_net_paid) AS total_store_sales,
        SUM(cs_net_paid) AS total_catalog_sales,
        SUM(ws_net_paid) AS total_web_sales,
        SUM(COALESCE(wr_net_loss, 0)) AS total_returns_loss
    FROM joined_data
    GROUP BY c_customer_sk, c_customer_id, ca_state, d_year, d_month_seq
)
SELECT
    c_customer_id,
    ca_state,
    d_year,
    d_month_seq,
    total_store_sales,
    total_catalog_sales,
    total_web_sales,
    total_returns_loss,
    (total_store_sales + total_catalog_sales + total_web_sales - total_returns_loss) AS net_total,
    RANK() OVER (PARTITION BY ca_state ORDER BY total_store_sales DESC) AS store_sales_rank,
    SUM(total_store_sales) OVER (PARTITION BY ca_state) AS state_store_sales_sum
FROM per_customer_month
WHERE total_store_sales > (
    SELECT MAX(total_store_sales) FROM per_customer_month WHERE ca_state = 'CA'
)
ORDER BY ca_state, store_sales_rank
LIMIT 100

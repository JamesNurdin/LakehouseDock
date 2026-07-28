WITH returns_union AS (
    SELECT
        cr_returned_date_sk AS returned_date_sk,
        cr_net_loss AS net_loss,
        cr_ship_mode_sk AS ship_mode_sk
    FROM catalog_returns
    UNION ALL
    SELECT
        wr_returned_date_sk,
        wr_net_loss,
        CAST(NULL AS INTEGER) AS ship_mode_sk
    FROM web_returns
),
sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_sales_price,
        ss.ss_net_profit,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_hdemo_sk,
        ss.ss_quantity
    FROM store_sales ss
)
SELECT
    s.s_store_name,
    d_sales.d_month_seq,
    SUM(sa.ss_sales_price) AS total_sales_price,
    SUM(sa.ss_net_profit) AS total_net_profit,
    SUM(r.net_loss) AS total_return_loss,
    COUNT(DISTINCT sa.ss_customer_sk) AS unique_customers,
    AVG(sa.ss_sales_price) AS avg_sales_price,
    (SELECT AVG(cr_net_loss) FROM catalog_returns) AS avg_catalog_return_loss
FROM sales sa
JOIN store s
    ON sa.ss_store_sk = s.s_store_sk
JOIN date_dim d_sales
    ON sa.ss_sold_date_sk = d_sales.d_date_sk
LEFT JOIN returns_union r
    ON r.returned_date_sk = d_sales.d_date_sk
LEFT JOIN ship_mode sm
    ON r.ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_demographics cd
    ON sa.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON sa.ss_hdemo_sk = hd.hd_demo_sk
JOIN inventory i
    ON i.inv_date_sk = d_sales.d_date_sk
JOIN date_dim d_inventory
    ON i.inv_date_sk = d_inventory.d_date_sk
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d_sales.d_date_sk
JOIN date_dim d_web_close
    ON ws.web_close_date_sk = d_web_close.d_date_sk
WHERE d_sales.d_year = 2001
  AND i.inv_warehouse_sk = 14
  AND s.s_state = 'TX'
  AND sm.sm_contract = 'A5BYO1qH8HGTTN'
GROUP BY GROUPING SETS (
    (s.s_store_name, d_sales.d_month_seq),
    (s.s_store_name),
    (d_sales.d_month_seq)
)
ORDER BY s.s_store_name, d_sales.d_month_seq

WITH sales_agg AS (
    SELECT
        cs.cs_order_number,
        cp.cp_department,
        p.p_promo_name,
        cs.cs_sold_time_sk AS sold_time_sk,
        cs.cs_net_profit,
        cs.cs_ext_sales_price,
        ca_bill.ca_address_sk AS bill_addr_sk,
        ca_ship.ca_address_sk AS ship_addr_sk,
        cd_bill.cd_demo_sk AS bill_demo_sk,
        cd_ship.cd_demo_sk AS ship_demo_sk,
        hd_bill.hd_demo_sk AS bill_hdemo_sk,
        hd_ship.hd_demo_sk AS ship_hdemo_sk
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN time_dim t_sales ON cs.cs_sold_time_sk = t_sales.t_time_sk
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
),
joined AS (
    SELECT
        s.cs_order_number,
        s.cp_department,
        s.p_promo_name,
        s.bill_addr_sk,
        s.cs_net_profit,
        s.cs_ext_sales_price,
        wr.wr_net_loss,
        r.r_reason_desc
    FROM sales_agg s
    JOIN web_returns wr ON wr.wr_returned_time_sk = s.sold_time_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
),
grouped AS (
    SELECT
        cp_department,
        p_promo_name,
        CASE WHEN SUM(cs_net_profit) > 0 THEN 'Positive' ELSE 'NegativeOrZero' END AS profit_status,
        COUNT(DISTINCT bill_addr_sk) AS distinct_bill_addresses,
        SUM(cs_net_profit) AS total_net_profit,
        SUM(cs_ext_sales_price) AS total_sales_amount,
        SUM(COALESCE(wr_net_loss, 0)) AS total_return_loss,
        SUM(CASE WHEN EXISTS (
                SELECT 1 FROM web_returns wr2
                WHERE wr2.wr_order_number = j.cs_order_number
                  AND wr2.wr_return_amt > 1000
            ) THEN 1 ELSE 0 END) AS orders_with_large_return
    FROM joined j
    GROUP BY ROLLUP (cp_department, p_promo_name)
)
SELECT
    cp_department,
    p_promo_name,
    profit_status,
    distinct_bill_addresses,
    total_net_profit,
    total_sales_amount,
    total_return_loss,
    orders_with_large_return,
    ROW_NUMBER() OVER (ORDER BY total_net_profit DESC) AS rank_by_profit,
    COUNT(*) OVER () AS total_groups
FROM grouped
WHERE total_net_profit IS NOT NULL
ORDER BY total_net_profit DESC
LIMIT 100

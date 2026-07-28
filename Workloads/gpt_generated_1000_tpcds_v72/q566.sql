WITH sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_bill_addr_sk,
        cs.cs_promo_sk,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit
    FROM catalog_sales cs
    JOIN date_dim d_sales ON cs.cs_sold_date_sk = d_sales.d_date_sk
    JOIN time_dim t_sales ON cs.cs_sold_time_sk = t_sales.t_time_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE d_sales.d_year = 2001
      AND p.p_purpose = 'Unknown'
      AND hd.hd_vehicle_count >= 2
),
returns AS (
    SELECT
        cr.cr_order_number,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_reason_sk,
        cr.cr_returned_date_sk
    FROM catalog_returns cr
    JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc LIKE '%defective%'
),
web_ret AS (
    SELECT
        wr.wr_order_number,
        wr.wr_return_amt,
        wr.wr_return_quantity,
        wr.wr_reason_sk
    FROM web_returns wr
    JOIN reason r2 ON wr.wr_reason_sk = r2.r_reason_sk
    WHERE r2.r_reason_desc LIKE '%defective%'
),
cust AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_preferred_cust_flag,
        c.c_current_hdemo_sk,
        c.c_current_addr_sk
    FROM customer c
    WHERE c.c_preferred_cust_flag = 'Y'
),
inv AS (
    SELECT
        i.inv_item_sk,
        i.inv_warehouse_sk,
        i.inv_quantity_on_hand,
        i.inv_date_sk
    FROM inventory i
    JOIN date_dim d_inv ON i.inv_date_sk = d_inv.d_date_sk
    WHERE d_inv.d_year = 2001
)
SELECT
    c.c_customer_id,
    d_sales.d_year,
    SUM(s.cs_net_profit) AS total_net_profit,
    COALESCE(SUM(r.cr_return_amount), 0) AS total_return_amount,
    COALESCE(SUM(wr.wr_return_amt), 0) AS total_web_return_amount,
    COALESCE(SUM(i.inv_quantity_on_hand), 0) AS total_inventory_on_hand,
    ROW_NUMBER() OVER (PARTITION BY d_sales.d_year ORDER BY SUM(s.cs_net_profit) DESC) AS profit_rank,
    DENSE_RANK() OVER (PARTITION BY d_sales.d_year ORDER BY COALESCE(SUM(r.cr_return_amount), 0) ASC) AS return_rank
FROM sales s
JOIN cust c ON s.cs_bill_customer_sk = c.c_customer_sk
JOIN date_dim d_sales ON s.cs_sold_date_sk = d_sales.d_date_sk
JOIN household_demographics hd ON s.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN returns r ON s.cs_order_number = r.cr_order_number
LEFT JOIN web_ret wr ON s.cs_order_number = wr.wr_order_number
LEFT JOIN inv i ON s.cs_item_sk = i.inv_item_sk
LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE EXISTS (
    SELECT 1 FROM web_returns wr2
    WHERE wr2.wr_order_number = s.cs_order_number
      AND wr2.wr_return_amt > 0
)
  AND ib.ib_upper_bound <= 80000
GROUP BY
    c.c_customer_id,
    d_sales.d_year,
    ca.ca_city,
    ca.ca_state
ORDER BY
    total_net_profit DESC,
    profit_rank
LIMIT 100

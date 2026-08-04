WITH cs_sample AS (
        SELECT *
        FROM catalog_sales
        TABLESAMPLE BERNOULLI (10)
    ),
    common_items AS (
        SELECT cs_item_sk AS item_sk FROM cs_sample WHERE cs_quantity > 5
        INTERSECT
        SELECT ws_item_sk FROM web_sales WHERE ws_quantity > 5
    )
SELECT
    d.d_year,
    d.d_day_name,
    c.c_customer_id,
    ca.ca_city,
    ss.ss_ticket_number,
    ss.ss_ext_sales_price,
    cs.cs_ext_sales_price,
    ws.ws_ext_sales_price,
    sr.sr_return_amt,
    wr.wr_return_amt,
    p.p_promo_name,
    ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY ss.ss_ext_sales_price DESC) AS sales_rank,
    CASE
        WHEN ss.ss_ext_sales_price > 1000 THEN 'High'
        WHEN ss.ss_ext_sales_price > 500 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category,
    (
        SELECT SUM(ws2.ws_ext_sales_price)
        FROM web_sales ws2
        WHERE ws2.ws_bill_customer_sk = ss.ss_customer_sk
    ) AS total_web_sales_for_customer
FROM date_dim d
JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
JOIN cs_sample cs ON cs.cs_sold_date_sk = d.d_date_sk
JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
    AND sr.sr_item_sk = ss.ss_item_sk
JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    AND wr.wr_item_sk = ws.ws_item_sk
JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
JOIN customer c ON c.c_first_sales_date_sk = d.d_date_sk
JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
WHERE d.d_day_name IN ('Saturday', 'Sunday')
  AND p.p_discount_active = 'Y'
  AND c.c_preferred_cust_flag = 'Y'
  AND cs.cs_item_sk IN (SELECT item_sk FROM common_items)
ORDER BY d.d_year DESC, sales_rank
OFFSET 0 FETCH FIRST 100 ROWS ONLY

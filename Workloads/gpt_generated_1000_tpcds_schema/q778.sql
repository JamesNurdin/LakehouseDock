WITH sales_agg AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_addr_sk,
        ss.ss_promo_sk,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        AVG(ss.ss_ext_sales_price) AS avg_sales,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
      AND cd.cd_credit_rating = 'Good'
      AND ss.ss_item_sk IN (SELECT inv_item_sk FROM inventory WHERE inv_quantity_on_hand > 600)
    GROUP BY
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_addr_sk,
        ss.ss_promo_sk
)
SELECT
    d.d_year,
    cc.cc_name,
    cp.cp_department,
    w.w_warehouse_name,
    ca.ca_city,
    cd.cd_credit_rating,
    wp.wp_url,
    SUM(COALESCE(sa.total_sales, 0) + COALESCE(sr.sr_return_amt_inc_tax, 0) - COALESCE(wr.wr_return_amt_inc_tax, 0)) AS net_amount,
    COUNT(DISTINCT sa.ss_ticket_number) AS distinct_sales_tickets,
    COUNT(DISTINCT sr.sr_ticket_number) AS distinct_return_tickets
FROM sales_agg sa
FULL OUTER JOIN store_returns sr
    ON sa.ss_ticket_number = sr.sr_ticket_number
LEFT JOIN date_dim d
    ON COALESCE(sa.ss_sold_date_sk, sr.sr_returned_date_sk) = d.d_date_sk
LEFT JOIN time_dim t
    ON COALESCE(sa.ss_sold_time_sk, sr.sr_return_time_sk) = t.t_time_sk
LEFT JOIN inventory inv
    ON inv.inv_date_sk = d.d_date_sk
    AND inv.inv_item_sk = sa.ss_item_sk
LEFT JOIN warehouse w
    ON inv.inv_warehouse_sk = w.w_warehouse_sk
LEFT JOIN call_center cc
    ON cc.cc_open_date_sk = d.d_date_sk
LEFT JOIN catalog_page cp
    ON cp.cp_start_date_sk = d.d_date_sk
LEFT JOIN customer_address ca
    ON ca.ca_address_sk = COALESCE(sa.ss_addr_sk, sr.sr_addr_sk)
LEFT JOIN customer_demographics cd
    ON cd.cd_demo_sk = COALESCE(sa.ss_cdemo_sk, sr.sr_cdemo_sk)
LEFT JOIN (SELECT * FROM web_page TABLESAMPLE BERNOULLI (10)) wp
    ON wp.wp_creation_date_sk = d.d_date_sk
LEFT JOIN web_returns wr
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE w.w_state = 'CA'
  AND cc.cc_state = 'CA'
  AND cp.cp_department = 'Electronics'
GROUP BY
    d.d_year,
    cc.cc_name,
    cp.cp_department,
    w.w_warehouse_name,
    ca.ca_city,
    cd.cd_credit_rating,
    wp.wp_url
ORDER BY net_amount DESC
OFFSET 0
LIMIT 100

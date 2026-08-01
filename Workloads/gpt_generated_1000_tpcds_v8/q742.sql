WITH
    sampled_inventory AS (
        SELECT inv_date_sk, inv_item_sk, inv_warehouse_sk, inv_quantity_on_hand
        FROM inventory TABLESAMPLE BERNOULLI (10)
    ),
    sales AS (
        SELECT
            ss.ss_ticket_number,
            ss.ss_sold_date_sk,
            ss.ss_sold_time_sk,
            ss.ss_item_sk,
            ss.ss_store_sk,
            ss.ss_quantity,
            ss.ss_sales_price,
            ss.ss_net_profit,
            d.d_year,
            i.i_category,
            i.i_item_id,
            s.s_store_name,
            s.s_state,
            ca.ca_city,
            cd.cd_gender,
            p.p_promo_name,
            p.p_discount_active,
            t.t_am_pm
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        LEFT JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
        LEFT JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    ),
    catalog_ret AS (
        SELECT
            cr.cr_returned_date_sk,
            cr.cr_item_sk,
            cr.cr_return_quantity,
            cr.cr_return_amount,
            cp.cp_department,
            r.r_reason_desc
        FROM catalog_returns cr
        JOIN date_dim d2 ON cr.cr_returned_date_sk = d2.d_date_sk
        JOIN item i2 ON cr.cr_item_sk = i2.i_item_sk
        LEFT JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    ),
    store_ret AS (
        SELECT
            sr.sr_ticket_number,
            sr.sr_return_quantity,
            sr.sr_return_amt,
            sr.sr_store_sk,
            r2.r_reason_desc AS sr_reason_desc
        FROM store_returns sr
        LEFT JOIN reason r2 ON sr.sr_reason_sk = r2.r_reason_sk
    ),
    web_ret AS (
        SELECT
            wr.wr_returned_date_sk,
            wr.wr_item_sk,
            wr.wr_return_quantity,
            wr.wr_return_amt,
            r3.r_reason_desc AS wr_reason_desc
        FROM web_returns wr
        LEFT JOIN reason r3 ON wr.wr_reason_sk = r3.r_reason_sk
    ),
    cross_set AS (
        SELECT seq
        FROM (VALUES (1), (2), (3)) AS t(seq)
    )
SELECT
    s.s_store_name,
    s.i_category,
    s.d_year,
    SUM(s.ss_sales_price * s.ss_quantity) AS total_sales_amount,
    COALESCE(SUM(cr.cr_return_amount), 0) AS total_return_amount,
    CASE
        WHEN SUM(s.ss_net_profit) > 100000 THEN 'HIGH'
        WHEN SUM(s.ss_net_profit) BETWEEN 50000 AND 100000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category,
    RANK() OVER (PARTITION BY s.s_store_name ORDER BY SUM(s.ss_sales_price * s.ss_quantity) DESC) AS sales_rank_by_store,
    ROW_NUMBER() OVER (ORDER BY SUM(s.ss_sales_price * s.ss_quantity) DESC) AS overall_row_num
FROM sales s
FULL OUTER JOIN catalog_ret cr
    ON s.ss_sold_date_sk = cr.cr_returned_date_sk
   AND s.ss_item_sk = cr.cr_item_sk
LEFT JOIN store_ret sr
    ON s.ss_ticket_number = sr.sr_ticket_number
LEFT JOIN web_ret wr
    ON s.ss_sold_date_sk = wr.wr_returned_date_sk
   AND s.ss_item_sk = wr.wr_item_sk
LEFT JOIN sampled_inventory inv
    ON s.ss_sold_date_sk = inv.inv_date_sk
   AND s.ss_item_sk = inv.inv_item_sk
CROSS JOIN cross_set cs
WHERE
    s.d_year = 2001
    AND s.i_category = 'Sports'
    AND s.s_state = 'CA'
    AND s.ca_city = 'Springfield'
    AND s.p_discount_active = 'Y'
    AND s.t_am_pm = 'PM'
    AND s.ss_ticket_number NOT IN (
        SELECT sr2.sr_ticket_number
        FROM store_returns sr2
        WHERE sr2.sr_return_quantity > 0
    )
GROUP BY GROUPING SETS (
    (s.s_store_name, s.i_category, s.d_year),
    (s.s_store_name, s.i_category),
    (s.i_category, s.d_year)
)
HAVING SUM(s.ss_sales_price * s.ss_quantity) > 1000
ORDER BY total_sales_amount DESC
LIMIT 100

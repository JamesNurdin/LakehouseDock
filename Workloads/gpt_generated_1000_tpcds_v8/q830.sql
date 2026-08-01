/*
goal: Identify the top catalog sales by year and department, enriched with customer‑household characteristics, promotion and warehouse details, and related return information. The query demonstrates deep multi‑table joins, a CASE expression, a correlated scalar subquery, an anti‑semi‑join filter, a LEFT OUTER JOIN, UNNEST of a derived array, aggregation, ordering and a global ROW_NUMBER.
*/
WITH sales_base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_bill_addr_sk,
        cs.cs_catalog_page_sk,
        cs.cs_warehouse_sk,
        cs.cs_promo_sk,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_quantity,
        cs.cs_item_sk
    FROM catalog_sales cs
    -- anti‑semi‑join: exclude orders that already appear as store returns on the same sold date
    WHERE cs.cs_order_number NOT IN (
        SELECT sr2.sr_ticket_number
        FROM store_returns sr2
        WHERE sr2.sr_returned_date_sk = cs.cs_sold_date_sk
    )
)
SELECT
    d_sold.d_year,
    cp.cp_department,
    CASE WHEN hd_bill.hd_dep_count > 3 THEN 'Large' ELSE 'Small' END AS household_size,
    SUM(sb.cs_ext_sales_price)                         AS total_sales,
    SUM(sb.cs_net_profit)                              AS total_profit,
    COUNT(DISTINCT sb.cs_order_number)                AS order_cnt,
    -- correlated scalar subquery: total refunded amount for the order
    SUM(
        COALESCE(
            (
                SELECT SUM(cr2.cr_return_amount)
                FROM catalog_returns cr2
                WHERE cr2.cr_order_number = sb.cs_order_number
            ),
            0
        )
    )                                                   AS total_refunded_amount,
    ROW_NUMBER() OVER (ORDER BY SUM(sb.cs_ext_sales_price) DESC) AS row_num,
    -- example of expanding a derived array (words in the page description)
    COUNT(DISTINCT word)                               AS distinct_word_cnt
FROM sales_base sb
JOIN date_dim d_sold          ON sb.cs_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t_sold          ON sb.cs_sold_time_sk = t_sold.t_time_sk
JOIN customer c_bill          ON sb.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN household_demographics hd_bill ON sb.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN customer_address ca_bill ON sb.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN catalog_page cp          ON sb.cs_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN catalog_returns cr  ON cr.cr_order_number = sb.cs_order_number   -- outer join example
JOIN warehouse w              ON sb.cs_warehouse_sk = w.w_warehouse_sk
JOIN promotion p              ON sb.cs_promo_sk = p.p_promo_sk
JOIN store_returns sr        ON sr.sr_ticket_number = sb.cs_order_number
JOIN date_dim d_return        ON sr.sr_returned_date_sk = d_return.d_date_sk
JOIN time_dim t_return        ON sr.sr_return_time_sk = t_return.t_time_sk
JOIN customer c_return        ON sr.sr_customer_sk = c_return.c_customer_sk
JOIN household_demographics hd_return ON sr.sr_hdemo_sk = hd_return.hd_demo_sk
JOIN customer_address ca_return ON sr.sr_addr_sk = ca_return.ca_address_sk
JOIN inventory inv            ON inv.inv_date_sk = d_sold.d_date_sk
                                 AND inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN web_page wp              ON wp.wp_customer_sk = c_bill.c_customer_sk
LEFT JOIN web_returns wr     ON wr.wr_web_page_sk = wp.wp_web_page_sk
                                 AND wr.wr_order_number = sb.cs_order_number   -- left outer join
-- expand a derived array from the catalog page description
CROSS JOIN UNNEST(split(cp.cp_description, ' ')) AS t(word)
GROUP BY
    d_sold.d_year,
    cp.cp_department,
    CASE WHEN hd_bill.hd_dep_count > 3 THEN 'Large' ELSE 'Small' END
ORDER BY total_sales DESC
LIMIT 100

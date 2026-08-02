/* Goal: Summarize 1999 electronic item sales by store and promotion, flag profit/loss, compute total returns from store and web, restrict to items that appear in both store and web returns, and demonstrate complex joins, outer joins, a full outer join, INTERSECT, ROW_NUMBER, CASE and correlated subqueries */
WITH
intersect_items AS (
    SELECT sr_item_sk AS item_sk FROM store_returns
    INTERSECT
    SELECT wr_item_sk AS item_sk FROM web_returns
),
full_store_ret AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        sr.sr_returned_date_sk,
        sr.sr_return_amt,
        sr.sr_ticket_number
    FROM store s
    FULL OUTER JOIN store_returns sr
        ON s.s_store_sk = sr.sr_store_sk
),
base_join AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_brand,
        i.i_category,
        s.s_store_sk,
        s.s_store_name,
        d_sales.d_date,
        d_sales.d_year,
        t_sales.t_hour,
        p.p_promo_name,
        cp.cp_description,
        d_closed.d_date AS store_closed_date,
        sr.sr_return_amt,
        wr.wr_return_amt
    FROM store_sales ss
    JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN time_dim t_sales ON ss.ss_sold_time_sk = t_sales.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd_sales ON ss.ss_cdemo_sk = cd_sales.cd_demo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT OUTER JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT OUTER JOIN catalog_page cp ON cp.cp_start_date_sk = d_sales.d_date_sk
    LEFT OUTER JOIN date_dim d_closed ON s.s_closed_date_sk = d_closed.d_date_sk
    LEFT OUTER JOIN promotion p2 ON p2.p_item_sk = i.i_item_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_store_sk = s.s_store_sk
    LEFT JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
    LEFT JOIN date_dim d_return ON sr.sr_returned_date_sk = d_return.d_date_sk
    LEFT JOIN time_dim t_return ON sr.sr_return_time_sk = t_return.t_time_sk
    LEFT JOIN customer_demographics cd_return ON sr.sr_cdemo_sk = cd_return.cd_demo_sk
    LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
    LEFT JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
    LEFT JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
    LEFT JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
    LEFT JOIN customer_demographics cd_wr_refunded ON wr.wr_refunded_cdemo_sk = cd_wr_refunded.cd_demo_sk
    LEFT JOIN customer_demographics cd_wr_returning ON wr.wr_returning_cdemo_sk = cd_wr_returning.cd_demo_sk
    LEFT JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN date_dim d_wp_creation ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
    LEFT JOIN date_dim d_wp_access ON wp.wp_access_date_sk = d_wp_access.d_date_sk
    LEFT JOIN date_dim d_cp_end ON cp.cp_end_date_sk = d_cp_end.d_date_sk
    WHERE d_sales.d_year = 1999
      AND i.i_category = 'Electronics'
),
aggregated AS (
    SELECT
        i_item_id,
        i_product_name,
        i_brand,
        i_category,
        s_store_name,
        d_date,
        t_hour,
        p_promo_name,
        cp_description,
        store_closed_date,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_paid) AS total_net_paid,
        SUM(ss_net_profit) AS total_net_profit,
        CASE WHEN SUM(ss_net_profit) > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag,
        i_item_sk
    FROM base_join
    GROUP BY
        i_item_id,
        i_product_name,
        i_brand,
        i_category,
        s_store_name,
        d_date,
        t_hour,
        p_promo_name,
        cp_description,
        store_closed_date,
        i_item_sk
)
SELECT
    ROW_NUMBER() OVER (ORDER BY total_net_paid DESC) AS rn,
    a.*, 
    (SELECT SUM(sr2.sr_return_amt) FROM store_returns sr2 WHERE sr2.sr_item_sk = a.i_item_sk) AS total_store_return_amount,
    (SELECT SUM(wr2.wr_return_amt) FROM web_returns wr2 WHERE wr2.wr_item_sk = a.i_item_sk) AS total_web_return_amount,
    intersect_items.item_sk,
    fsr.sr_return_amt AS full_store_return_amt
FROM aggregated a
JOIN intersect_items ON a.i_item_sk = intersect_items.item_sk
LEFT JOIN full_store_ret fsr ON a.s_store_name = fsr.s_store_name
LIMIT 100

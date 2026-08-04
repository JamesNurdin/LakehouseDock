WITH promo_sales AS (
    SELECT
        p.p_promo_id AS promo_id,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
        SUM(cs.cs_net_paid) AS total_net_paid,
        CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
        NULL AS store_id,
        NULL AS distinct_tickets,
        NULL AS total_return_amount,
        NULL AS return_flag,
        NULL AS web_page_id,
        NULL AS web_distinct_orders,
        NULL AS web_total_return,
        NULL AS web_return_flag
    FROM
        catalog_sales cs
    RIGHT OUTER JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    LEFT JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
    LEFT JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    GROUP BY p.p_promo_id
),
store_return_stats AS (
    SELECT
        s.s_store_id AS store_id,
        NULL AS promo_id,
        NULL AS distinct_orders,
        NULL AS total_net_paid,
        NULL AS profit_flag,
        COUNT(DISTINCT sr.sr_ticket_number) AS distinct_tickets,
        SUM(sr.sr_return_amt) AS total_return_amount,
        CASE WHEN SUM(sr.sr_net_loss) > 0 THEN 'Loss' ELSE 'Gain' END AS return_flag,
        NULL AS web_page_id,
        NULL AS web_distinct_orders,
        NULL AS web_total_return,
        NULL AS web_return_flag
    FROM
        store_returns sr
    FULL OUTER JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    LEFT JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    GROUP BY s.s_store_id
),
web_return_stats AS (
    SELECT
        wp.wp_web_page_id AS web_page_id,
        NULL AS promo_id,
        NULL AS distinct_orders,
        NULL AS total_net_paid,
        NULL AS profit_flag,
        NULL AS store_id,
        NULL AS distinct_tickets,
        NULL AS total_return_amount,
        NULL AS return_flag,
        COUNT(DISTINCT wr.wr_order_number) AS web_distinct_orders,
        SUM(wr.wr_return_amt) AS web_total_return,
        CASE WHEN SUM(wr.wr_net_loss) > 0 THEN 'Loss' ELSE 'Gain' END AS web_return_flag
    FROM
        web_returns wr
    LEFT JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    LEFT JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    GROUP BY wp.wp_web_page_id
),
combined AS (
    SELECT * FROM promo_sales
    UNION DISTINCT
    SELECT * FROM store_return_stats
    UNION DISTINCT
    SELECT * FROM web_return_stats
)
SELECT
    combined.promo_id,
    combined.distinct_orders,
    combined.total_net_paid,
    combined.profit_flag,
    combined.store_id,
    combined.distinct_tickets,
    combined.total_return_amount,
    combined.return_flag,
    combined.web_page_id,
    combined.web_distinct_orders,
    combined.web_total_return,
    combined.web_return_flag,
    (SELECT MAX(d_date) FROM date_dim) AS max_date
FROM combined
ORDER BY COALESCE(combined.promo_id, combined.store_id, combined.web_page_id) ASC
LIMIT 100

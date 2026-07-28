WITH agg_promo AS (
    SELECT
        p.p_promo_id,
        p.p_promo_name,
        p.p_channel_demo,
        COUNT(*) AS sales_transactions,
        SUM(ws.ws_net_paid_inc_ship_tax) AS total_net_paid,
        AVG(ws.ws_net_paid_inc_ship_tax) AS avg_net_paid,
        MAX(ws.ws_net_paid_inc_ship_tax) AS max_single_payment
    FROM
        tpcds.promotion p
        JOIN tpcds.web_sales ws
            ON ws.ws_promo_sk = p.p_promo_sk
    WHERE
        ws.ws_net_paid_inc_ship_tax > 500
        AND ws.ws_ext_tax < 200
        AND ws.ws_quantity >= 1
        AND p.p_channel_demo = 'N'
        AND p.p_purpose <> 'Unknown'
        AND p.p_end_date_sk BETWEEN 2450400 AND 2450800
        AND NOT EXISTS (
            SELECT 1
            FROM tpcds.web_sales ws2
            WHERE ws2.ws_promo_sk = p.p_promo_sk
              AND ws2.ws_ext_tax > 250
        )
    GROUP BY
        p.p_promo_id,
        p.p_promo_name,
        p.p_channel_demo
)
SELECT
    ap.p_promo_id,
    ap.p_promo_name,
    ap.p_channel_demo,
    ap.sales_transactions,
    ap.total_net_paid,
    ap.avg_net_paid,
    ap.max_single_payment,
    ROW_NUMBER() OVER (ORDER BY ap.total_net_paid DESC) AS sales_rank,
    CASE
        WHEN ap.total_net_paid > (
            SELECT MAX(total_sum)
            FROM (
                SELECT SUM(ws_net_paid_inc_ship_tax) AS total_sum
                FROM tpcds.web_sales
                GROUP BY ws_promo_sk
            ) AS sub
        ) THEN 'Above Overall Max'
        ELSE 'Below Overall Max'
    END AS performance_category
FROM
    agg_promo ap
ORDER BY
    ap.total_net_paid DESC,
    sales_rank
LIMIT 100

WITH base AS (
    SELECT
        r.r_reason_id AS reason_id,
        d_ret.d_year AS year,
        SUM(cr.cr_net_loss)               AS net_loss,
        SUM(ss.ss_net_profit)             AS net_profit,
        COUNT(DISTINCT cr.cr_order_number) AS return_cnt,
        COUNT(DISTINCT ss.ss_ticket_number) AS sales_cnt
    FROM catalog_returns cr
    JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd_ref
        ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN store_sales ss
        ON ss.ss_sold_date_sk = d_ret.d_date_sk
    JOIN household_demographics hd_sales
        ON ss.ss_hdemo_sk = hd_sales.hd_demo_sk
    JOIN web_page wp
        ON wp.wp_creation_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year BETWEEN 1900 AND 1918
      AND r.r_reason_sk IN (5, 12, 13)
      AND hd_ref.hd_vehicle_count > 2
      AND hd_ref.hd_dep_count <= 3
      AND wp.wp_image_count BETWEEN 2 AND 5
    GROUP BY r.r_reason_id, d_ret.d_year
),
agg AS (
    SELECT
        reason_id,
        AVG(net_loss)     AS avg_net_loss,
        SUM(net_profit)   AS sum_net_profit,
        SUM(return_cnt)   AS total_returns,
        SUM(sales_cnt)    AS total_sales
    FROM base
    GROUP BY reason_id
    HAVING AVG(net_loss) > 1000
)
SELECT
    ROW_NUMBER() OVER (ORDER BY avg_net_loss DESC) AS row_num,
    reason_id,
    avg_net_loss,
    sum_net_profit,
    total_returns,
    total_sales
FROM agg
ORDER BY avg_net_loss DESC
LIMIT 100

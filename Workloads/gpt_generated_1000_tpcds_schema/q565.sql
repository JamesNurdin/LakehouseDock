WITH sampled_sales AS (
    SELECT *
    FROM store_sales TABLESAMPLE BERNOULLI (10)
),

store_set_a AS (
    SELECT s_store_sk
    FROM store
    WHERE s_state = 'CA' AND s_gmt_offset > -5
),

store_set_b AS (
    SELECT s_store_sk
    FROM store
    WHERE s_tax_percentage > 5
),

store_diff AS (
    SELECT s_store_sk
    FROM store_set_a
    EXCEPT
    SELECT s_store_sk
    FROM store_set_b
),

joined AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_store_sk,
        i.i_category_id,
        i.i_manufact_id,
        s.s_state,
        s.s_rec_start_date,
        td.t_hour,
        cr.cr_return_amt_inc_tax,
        cr.cr_reason_sk,
        sm.sm_type,
        r.r_reason_desc,
        ss.ss_ext_tax,
        ss.ss_ext_list_price,
        ss.ss_net_paid
    FROM sampled_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN catalog_returns cr ON cr.cr_returned_time_sk = td.t_time_sk
        AND cr.cr_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE ss.ss_store_sk IN (SELECT s_store_sk FROM store_diff)
      AND i.i_category_id IN (1, 4, 8)
      AND s.s_state = 'CA'
      AND s.s_rec_start_date >= DATE '2000-01-01'
      AND td.t_hour BETWEEN 9 AND 17
      AND cr.cr_return_amt_inc_tax > 500
),

agg1 AS (
    SELECT
        i_category_id,
        sm_type,
        r_reason_desc,
        COUNT(*) AS cnt,
        SUM(ss_ext_tax) AS total_tax,
        AVG(ss_ext_list_price) AS avg_list_price,
        SUM(ss_net_paid) AS total_net_paid
    FROM joined
    GROUP BY i_category_id, sm_type, r_reason_desc
),

distinct_reasons AS (
    SELECT DISTINCT r_reason_desc
    FROM agg1
),

final AS (
    SELECT
        a.i_category_id,
        a.sm_type,
        a.r_reason_desc,
        a.cnt,
        a.total_tax,
        a.avg_list_price,
        a.total_net_paid,
        ROW_NUMBER() OVER (ORDER BY a.total_net_paid DESC) AS rn
    FROM agg1 a
    WHERE a.cnt > 10
      AND a.total_tax > 100
      AND a.avg_list_price BETWEEN 100 AND 1000
      AND a.r_reason_desc IN (SELECT r_reason_desc FROM distinct_reasons)
)
SELECT *
FROM final
WHERE rn <= 100
LIMIT 100

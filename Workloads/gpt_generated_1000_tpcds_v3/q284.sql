WITH joined_data AS (
    SELECT
        d.d_date_sk,
        d.d_date,
        d.d_year,
        d.d_fy_quarter_seq,
        i.inv_item_sk,
        i.inv_quantity_on_hand,
        w.w_warehouse_sk,
        w.w_warehouse_name,
        w.w_city,
        w.w_state,
        wr.wr_returned_date_sk,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_net_loss,
        wp.wp_web_page_sk,
        wp.wp_type,
        wp.wp_char_count
    FROM date_dim d
    INNER JOIN inventory i
        ON i.inv_date_sk = d.d_date_sk
    INNER JOIN warehouse w
        ON i.inv_warehouse_sk = w.w_warehouse_sk
    INNER JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
    INNER JOIN web_page wp
        ON wp.wp_web_page_sk = wr.wr_web_page_sk
    WHERE d.d_year = 2001
      AND i.inv_quantity_on_hand BETWEEN 200 AND 900
      AND w.w_state IN ('CA', 'TX')
      AND w.w_city NOT LIKE '%York%'
      AND wp.wp_type IN ('Content', 'Product')
      AND wr.wr_return_quantity > 0
),
agg_qtr2 AS (
    SELECT
        jd.w_warehouse_name,
        jd.w_city,
        jd.w_state,
        jd.wp_type,
        SUM(jd.wr_return_amt) AS total_return_amt,
        SUM(jd.wr_net_loss) AS total_net_loss,
        AVG(jd.inv_quantity_on_hand) AS avg_quantity_on_hand,
        COUNT(*) AS return_cnt
    FROM joined_data jd
    WHERE jd.d_fy_quarter_seq = 2
    GROUP BY jd.w_warehouse_name, jd.w_city, jd.w_state, jd.wp_type
),
agg_qtr12 AS (
    SELECT
        jd.w_warehouse_name,
        jd.w_city,
        jd.w_state,
        jd.wp_type,
        SUM(jd.wr_return_amt) AS total_return_amt,
        SUM(jd.wr_net_loss) AS total_net_loss,
        AVG(jd.inv_quantity_on_hand) AS avg_quantity_on_hand,
        COUNT(*) AS return_cnt
    FROM joined_data jd
    WHERE jd.d_fy_quarter_seq = 12
    GROUP BY jd.w_warehouse_name, jd.w_city, jd.w_state, jd.wp_type
)
SELECT
    period,
    w_warehouse_name,
    w_city,
    w_state,
    wp_type,
    total_return_amt,
    total_net_loss,
    avg_quantity_on_hand,
    return_cnt,
    CASE WHEN total_net_loss > 5000 THEN 'High' WHEN total_net_loss > 1000 THEN 'Medium' ELSE 'Low' END AS loss_category,
    loss_rank
FROM (
    SELECT
        'FY_Qtr_2' AS period,
        q2.w_warehouse_name,
        q2.w_city,
        q2.w_state,
        q2.wp_type,
        q2.total_return_amt,
        q2.total_net_loss,
        q2.avg_quantity_on_hand,
        q2.return_cnt,
        RANK() OVER (PARTITION BY q2.wp_type ORDER BY q2.total_net_loss DESC) AS loss_rank
    FROM agg_qtr2 q2
    UNION ALL
    SELECT
        'FY_Qtr_12' AS period,
        q12.w_warehouse_name,
        q12.w_city,
        q12.w_state,
        q12.wp_type,
        q12.total_return_amt,
        q12.total_net_loss,
        q12.avg_quantity_on_hand,
        q12.return_cnt,
        RANK() OVER (PARTITION BY q12.wp_type ORDER BY q12.total_net_loss DESC) AS loss_rank
    FROM agg_qtr12 q12
) final
ORDER BY period, loss_rank
LIMIT 100

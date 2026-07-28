SELECT
    s.store_id,
    s.store_name,
    s.amount,
    s.metric_type,
    s.max_cc_gmt_offset
FROM (
    SELECT
        st.s_store_id AS store_id,
        st.s_store_name AS store_name,
        SUM(ss.ss_net_paid) AS amount,
        'sales' AS metric_type,
        (SELECT MAX(cc.cc_gmt_offset) FROM call_center cc) AS max_cc_gmt_offset
    FROM store_sales ss
    JOIN store st ON ss.ss_store_sk = st.s_store_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE td.t_hour BETWEEN 9 AND 17
      AND EXISTS (
          SELECT 1
          FROM promotion p
          WHERE p.p_item_sk = i.i_item_sk
            AND p.p_discount_active = 'Y'
      )
    GROUP BY st.s_store_id, st.s_store_name
    UNION ALL
    SELECT
        st.s_store_id AS store_id,
        st.s_store_name AS store_name,
        SUM(sr.sr_return_amt) AS amount,
        'returns' AS metric_type,
        (SELECT MAX(cc.cc_gmt_offset) FROM call_center cc) AS max_cc_gmt_offset
    FROM store_returns sr
    JOIN store st ON sr.sr_store_sk = st.s_store_sk
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 9 AND 17
    GROUP BY st.s_store_id, st.s_store_name
) s
ORDER BY s.amount DESC, s.metric_type
LIMIT 100

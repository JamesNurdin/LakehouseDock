WITH cs_agg AS (
    SELECT
        cs.cs_call_center_sk,
        cs.cs_sold_time_sk,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_ext_tax) AS total_tax,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    WHERE cs.cs_list_price > 30
      AND cs.cs_ext_tax > 20
      AND cs.cs_net_paid_inc_tax >= 100
    GROUP BY cs.cs_call_center_sk, cs.cs_sold_time_sk
),
joined AS (
    SELECT
        cc.cc_call_center_id,
        t.t_shift,
        t.t_minute,
        MAX(cs_agg.total_net_paid) AS total_net_paid,
        MAX(cs_agg.total_tax) AS total_tax,
        MAX(cs_agg.sales_cnt) AS sales_cnt,
        SUM(sr.sr_return_amt) AS total_store_return_amt,
        SUM(wr.wr_return_amt) AS total_web_return_amt,
        SUM(sr.sr_fee) AS total_store_fee,
        SUM(wr.wr_fee) AS total_web_fee
    FROM cs_agg
    JOIN call_center cc ON cs_agg.cs_call_center_sk = cc.cc_call_center_sk
    JOIN time_dim t ON cs_agg.cs_sold_time_sk = t.t_time_sk
    LEFT JOIN store_returns sr ON sr.sr_return_time_sk = t.t_time_sk AND sr.sr_fee > 5
    LEFT JOIN web_returns wr ON wr.wr_returned_time_sk = t.t_time_sk AND wr.wr_fee > 5
    WHERE t.t_shift = 'first'
      AND t.t_minute >= 5
      AND cc.cc_employees > 50
      AND cc.cc_gmt_offset BETWEEN -5 AND 5
      AND EXISTS (
            SELECT 1 FROM web_returns wr2
            WHERE wr2.wr_returned_time_sk = t.t_time_sk
              AND wr2.wr_return_amt > 100
      )
    GROUP BY ROLLUP (cc.cc_call_center_id, t.t_shift, t.t_minute)
)
SELECT
    cc_call_center_id,
    t_shift,
    t_minute,
    total_net_paid,
    total_tax,
    sales_cnt,
    total_store_return_amt,
    total_web_return_amt,
    total_store_fee,
    total_web_fee,
    RANK() OVER (PARTITION BY cc_call_center_id ORDER BY total_net_paid DESC) AS sales_rank,
    CASE
        WHEN (COALESCE(total_store_return_amt, 0) + COALESCE(total_web_return_amt, 0)) > total_net_paid * 0.5
        THEN 'High Return'
        ELSE 'Normal Return'
    END AS return_category
FROM joined
ORDER BY cc_call_center_id, t_shift, t_minute

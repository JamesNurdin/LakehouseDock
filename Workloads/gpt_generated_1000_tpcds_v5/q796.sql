WITH agg_returns AS (
    SELECT
        sr.sr_item_sk,
        d.d_year,
        d.d_month_seq,
        SUM(sr.sr_net_loss) AS total_net_loss,
        SUM(sr.sr_return_quantity) AS total_qty,
        AVG(sr.sr_return_amt_inc_tax) AS avg_return_amt_inc_tax
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_current_month = 'Y'
      AND d.d_quarter_name = '1904Q3'
      AND t.t_am_pm = 'PM'
      AND i.i_brand_id IN (
          SELECT DISTINCT i2.i_brand_id
          FROM item i2
          WHERE i2.i_color = 'Red'
      )
    GROUP BY sr.sr_item_sk, d.d_year, d.d_month_seq
)
SELECT
    ar.d_year,
    ar.d_month_seq,
    i.i_product_name,
    i.i_brand,
    ar.total_net_loss,
    ar.total_qty,
    ar.avg_return_amt_inc_tax,
    CASE WHEN ar.total_net_loss > 1000 THEN 'High' ELSE 'Low' END AS loss_category,
    RANK() OVER (PARTITION BY ar.d_year, ar.d_month_seq ORDER BY ar.total_net_loss DESC) AS net_loss_rank
FROM agg_returns ar
JOIN item i ON ar.sr_item_sk = i.i_item_sk
WHERE EXISTS (
    SELECT 1
    FROM call_center cc
    JOIN date_dim cd ON cc.cc_closed_date_sk = cd.d_date_sk
    WHERE cc.cc_state = 'CA'
      AND cd.d_year = ar.d_year
      AND cd.d_month_seq = ar.d_month_seq
)
ORDER BY net_loss_rank, ar.total_net_loss DESC
LIMIT 100

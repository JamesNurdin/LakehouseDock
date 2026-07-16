WITH sales_agg AS (
    SELECT
        ss.ss_store_sk AS store_sk,
        d.d_year,
        d.d_month_seq,
        i.i_category,
        SUM(ss.ss_net_profit) AS total_net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE cd.cd_gender = 'M'
      AND cd.cd_marital_status = 'M'
      AND hd.hd_vehicle_count >= 2
      AND t.t_hour BETWEEN 9 AND 17
      AND i.i_current_price > 20
    GROUP BY ss.ss_store_sk, d.d_year, d.d_month_seq, i.i_category
),
returns_agg AS (
    SELECT
        dr.d_year,
        dr.d_month_seq,
        i.i_category,
        SUM(wr.wr_net_loss) AS total_return_loss
    FROM web_returns wr
    JOIN date_dim dr ON wr.wr_returned_date_sk = dr.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN customer_demographics cd_ref ON wr.wr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN household_demographics hd_ref ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN time_dim tr ON wr.wr_returned_time_sk = tr.t_time_sk
    WHERE cd_ref.cd_gender = 'M'
      AND cd_ref.cd_marital_status = 'M'
      AND hd_ref.hd_vehicle_count >= 2
      AND tr.t_hour BETWEEN 9 AND 17
      AND i.i_current_price > 20
    GROUP BY dr.d_year, dr.d_month_seq, i.i_category
)
SELECT
    s.store_sk,
    s.d_year,
    s.d_month_seq,
    s.i_category,
    s.total_net_profit,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    s.total_net_profit - COALESCE(r.total_return_loss, 0) AS net_contribution,
    RANK() OVER (PARTITION BY s.d_year, s.d_month_seq ORDER BY s.total_net_profit - COALESCE(r.total_return_loss, 0) DESC) AS store_rank
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.d_year = r.d_year
   AND s.d_month_seq = r.d_month_seq
   AND s.i_category = r.i_category
ORDER BY s.d_year, s.d_month_seq, net_contribution DESC
LIMIT 100

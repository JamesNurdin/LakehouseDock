SELECT
    agg.cc_name,
    agg.cc_manager,
    agg.cc_tax_percentage,
    agg.year,
    agg.month_seq,
    agg.cc_open_month,
    agg.store_name,
    agg.city,
    agg.floor_space,
    agg.wp_type,
    agg.wp_url,
    agg.wp_access_weekend,
    agg.total_net_loss,
    agg.avg_fee,
    agg.ticket_cnt,
    ROW_NUMBER() OVER (PARTITION BY agg.year ORDER BY agg.total_net_loss DESC) AS loss_rank
FROM (
    SELECT
        cc.cc_name,
        cc.cc_manager,
        cc.cc_tax_percentage,
        d_ret.d_year AS year,
        d_ret.d_month_seq AS month_seq,
        d_open.d_current_month AS cc_open_month,
        s.s_store_name AS store_name,
        s.s_city AS city,
        s.s_floor_space AS floor_space,
        wp.wp_type,
        wp.wp_url,
        d_access.d_weekend AS wp_access_weekend,
        SUM(sr.sr_net_loss) AS total_net_loss,
        AVG(sr.sr_fee) AS avg_fee,
        COUNT(DISTINCT sr.sr_ticket_number) AS ticket_cnt
    FROM store_returns sr
    JOIN date_dim d_ret
      ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN store s
      ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d_store
      ON s.s_closed_date_sk = d_store.d_date_sk
    JOIN call_center cc
      ON cc.cc_closed_date_sk = d_store.d_date_sk
    JOIN date_dim d_open
      ON cc.cc_open_date_sk = d_open.d_date_sk
    JOIN web_page wp
      ON wp.wp_creation_date_sk = d_store.d_date_sk
    JOIN date_dim d_access
      ON wp.wp_access_date_sk = d_access.d_date_sk
    WHERE
      cc.cc_tax_percentage > 0
      AND s.s_floor_space > 0
      AND d_ret.d_year = 2022
    GROUP BY
      cc.cc_name,
      cc.cc_manager,
      cc.cc_tax_percentage,
      d_ret.d_year,
      d_ret.d_month_seq,
      d_open.d_current_month,
      s.s_store_name,
      s.s_city,
      s.s_floor_space,
      wp.wp_type,
      wp.wp_url,
      d_access.d_weekend
) AS agg
ORDER BY agg.total_net_loss DESC
LIMIT 50

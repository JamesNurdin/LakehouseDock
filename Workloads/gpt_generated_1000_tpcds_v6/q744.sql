WITH base AS (
    SELECT
        s.s_store_id,
        d_ret.d_date,
        sr.sr_net_loss AS sr_net_loss,
        wr.wr_net_loss AS wr_net_loss,
        s.s_state,
        i.inv_quantity_on_hand,
        cp.cp_catalog_number,
        cc.cc_gmt_offset,
        wp.wp_type,
        t_ret.t_hour
    FROM store_returns sr
    JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN time_dim t_ret ON sr.sr_return_time_sk = t_ret.t_time_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN inventory i ON i.inv_date_sk = d_ret.d_date_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = d_ret.d_date_sk
        AND wr.wr_returned_time_sk = t_ret.t_time_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d_ret.d_date_sk
    JOIN call_center cc ON cc.cc_closed_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year = 2001
      AND s.s_state = 'CA'
      AND i.inv_quantity_on_hand > 200
      AND cp.cp_catalog_number BETWEEN 5 AND 20
      AND cc.cc_gmt_offset BETWEEN -5 AND 0
      AND wp.wp_type = 'content'
      AND sr.sr_return_amt > 50
      AND t_ret.t_hour BETWEEN 9 AND 17
      AND EXISTS (
          SELECT 1
          FROM call_center cc2
          WHERE cc2.cc_company = s.s_company_id
            AND cc2.cc_tax_percentage < 5
      )
),
agg AS (
    SELECT
        s_store_id,
        d_date,
        SUM(sr_net_loss) AS store_return_loss,
        SUM(wr_net_loss) AS web_return_loss,
        SUM(sr_net_loss + wr_net_loss) AS total_loss
    FROM base
    GROUP BY s_store_id, d_date
)
SELECT
    s_store_id,
    d_date,
    store_return_loss,
    web_return_loss,
    total_loss,
    ROW_NUMBER() OVER (PARTITION BY d_date ORDER BY total_loss DESC) AS loss_rank
FROM agg
WHERE total_loss > 0
ORDER BY total_loss DESC, loss_rank
LIMIT 100

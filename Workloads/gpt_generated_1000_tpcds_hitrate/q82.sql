WITH store_ret_agg AS (
    SELECT
        sr.sr_reason_sk,
        d.d_year,
        i.i_category,
        i.i_item_sk,
        SUM(sr.sr_net_loss) AS total_net_loss,
        SUM(sr.sr_return_quantity) AS total_return_qty
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    GROUP BY sr.sr_reason_sk, d.d_year, i.i_category, i.i_item_sk
)
SELECT
    r.r_reason_desc,
    agg.i_category,
    agg.d_year,
    agg.total_net_loss,
    agg.total_return_qty,
    cr.cr_return_amount,
    ws.ws_net_paid,
    p.p_promo_name,
    ROW_NUMBER() OVER (PARTITION BY agg.d_year ORDER BY agg.total_net_loss DESC) AS loss_rank,
    CASE WHEN agg.total_net_loss > 15000 THEN 'High' ELSE 'Medium' END AS loss_level
FROM store_ret_agg agg
JOIN reason r
    ON agg.sr_reason_sk = r.r_reason_sk
JOIN catalog_returns cr
    ON cr.cr_reason_sk = r.r_reason_sk
JOIN date_dim d_cr
    ON cr.cr_returned_date_sk = d_cr.d_date_sk
JOIN customer_address ca
    ON cr.cr_refunded_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd
    ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN promotion p
    ON p.p_item_sk = agg.i_item_sk
JOIN date_dim d_p_start
    ON p.p_start_date_sk = d_p_start.d_date_sk
JOIN date_dim d_p_end
    ON p.p_end_date_sk = d_p_end.d_date_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d_cr.d_date_sk  -- align web sales to the same year as catalog return
JOIN time_dim t_ws
    ON ws.ws_sold_time_sk = t_ws.t_time_sk
JOIN store_sales ss
    ON ss.ss_item_sk = agg.i_item_sk
JOIN date_dim d_ss
    ON ss.ss_sold_date_sk = d_ss.d_date_sk
WHERE
    d_cr.d_year = 2000                           -- filter 1: catalog returns from year 2000
    AND t_ws.t_shift = 'second'                  -- filter 2: sales occurring in the second shift
    AND sm.sm_type = 'AIR'                       -- filter 3: ship mode of type AIR
    AND p.p_discount_active = 'Y'                -- filter 4: only active promotions
    AND agg.i_category = 'Sports'                -- additional filter for product category
    AND d_ss.d_year = agg.d_year                  -- keep store sales in the same year as the aggregated returns
ORDER BY
    agg.d_year,
    loss_rank

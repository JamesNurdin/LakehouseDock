WITH base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_sales_price,
        ss.ss_net_paid,
        ss.ss_net_profit,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_net_loss AS sr_net_loss,
        sr.sr_fee,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss AS cr_net_loss,
        cr.cr_fee,
        cc.cc_call_center_id,
        sm.sm_type,
        s.s_store_name,
        s.s_state,
        d.d_date,
        d.d_year,
        t.t_hour,
        cd.cd_purchase_estimate,
        r.r_reason_sk,
        r.r_reason_desc
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store_returns sr
        ON sr.sr_item_sk = ss.ss_item_sk
       AND sr.sr_ticket_number = ss.ss_ticket_number
       AND sr.sr_returned_date_sk = d.d_date_sk
       AND sr.sr_return_time_sk = t.t_time_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
       AND cr.cr_returned_time_sk = t.t_time_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 2002
      AND s.s_state = 'CA'
      AND r.r_reason_desc LIKE '%damaged%'
      AND cd.cd_purchase_estimate >= 8000
      AND sm.sm_type = 'AIR'
      AND t.t_hour BETWEEN 9 AND 17
),
agg AS (
    SELECT
        d_date,
        s_store_name,
        s_state,
        r_reason_desc,
        r_reason_sk,
        d_year,
        SUM(COALESCE(sr_net_loss, 0)) AS sr_total_net_loss,
        SUM(COALESCE(cr_net_loss, 0)) AS cr_total_net_loss,
        SUM(COALESCE(sr_fee, 0)) AS sr_total_fee,
        SUM(COALESCE(cr_fee, 0)) AS cr_total_fee
    FROM base
    GROUP BY
        d_date,
        s_store_name,
        s_state,
        r_reason_desc,
        r_reason_sk,
        d_year
)
SELECT
    d_date,
    s_store_name,
    s_state,
    r_reason_desc,
    (sr_total_net_loss + cr_total_net_loss) AS total_net_loss,
    CASE WHEN (sr_total_fee + cr_total_fee) > 100 THEN 'High' ELSE 'Low' END AS fee_category,
    RANK() OVER (PARTITION BY d_year ORDER BY (sr_total_net_loss + cr_total_net_loss) DESC) AS loss_rank
FROM agg
WHERE EXISTS (
    SELECT 1
    FROM web_returns wr
    WHERE wr.wr_reason_sk = agg.r_reason_sk
)
LIMIT 100

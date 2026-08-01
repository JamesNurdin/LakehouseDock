WITH base AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d_sold.d_year,
        d_sold.d_month_seq,
        i.i_item_id,
        i.i_product_name,
        SUM(sr.sr_net_loss) AS total_store_loss,
        SUM(cr.cr_net_loss) AS total_catalog_loss,
        SUM(sr.sr_return_quantity) AS total_store_return_qty,
        SUM(cr.cr_return_quantity) AS total_catalog_return_qty,
        d_sold.d_date AS sold_date
    FROM
        call_center cc
        JOIN catalog_returns cr ON cr.cr_call_center_sk = cc.cc_call_center_sk
        JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        JOIN date_dim d_return ON cr.cr_returned_date_sk = d_return.d_date_sk
        JOIN time_dim t_return ON cr.cr_returned_time_sk = t_return.t_time_sk
        JOIN item i ON cr.cr_item_sk = i.i_item_sk
        JOIN promotion p ON p.p_item_sk = i.i_item_sk
        JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
            AND sr.sr_item_sk = ss.ss_item_sk
        JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
        JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN date_dim d_sold ON ss.ss_sold_date_sk = d_sold.d_date_sk
        JOIN time_dim t_sold ON ss.ss_sold_time_sk = t_sold.t_time_sk
    WHERE
        cc.cc_state = 'CA'
        AND p.p_channel_dmail = 'Y'
        AND i.i_current_price > 100
        AND cd.cd_purchase_estimate >= 6000
        AND d_sold.d_year = 2000
        AND t_sold.t_hour BETWEEN 9 AND 17
        AND sr.sr_net_loss > 0
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        d_sold.d_year,
        d_sold.d_month_seq,
        i.i_item_id,
        i.i_product_name,
        d_sold.d_date
)
SELECT
    s_store_id,
    s_store_name,
    d_year,
    d_month_seq,
    i_item_id,
    i_product_name,
    total_store_loss,
    total_catalog_loss,
    total_store_return_qty,
    total_catalog_return_qty,
    SUM(total_store_loss) OVER (
        PARTITION BY s_store_id
        ORDER BY sold_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_store_loss,
    RANK() OVER (
        PARTITION BY d_year
        ORDER BY total_store_loss DESC
    ) AS store_loss_rank
FROM base
ORDER BY cumulative_store_loss DESC, store_loss_rank
LIMIT 100

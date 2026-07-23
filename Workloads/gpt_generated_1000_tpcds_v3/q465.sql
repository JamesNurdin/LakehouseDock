WITH
store_sales_agg AS (
    SELECT
        ss.ss_item_sk,
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_cdemo_sk,
        ss.ss_hdemo_sk,
        ss.ss_addr_sk,
        ss.ss_promo_sk,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit
    FROM store_sales ss
    GROUP BY
        ss.ss_item_sk,
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_cdemo_sk,
        ss.ss_hdemo_sk,
        ss.ss_addr_sk,
        ss.ss_promo_sk
),
joined_data AS (
    SELECT
        d_sales.d_year AS sales_year,
        p.p_promo_name,
        r_sr.r_reason_desc AS store_return_reason,
        sm.sm_type AS ship_mode_type,
        ca.ca_state,
        hd.hd_buy_potential,
        cd.cd_gender,
        ss_agg.total_net_paid,
        ss_agg.total_net_profit,
        cr.cr_return_amount,
        wr.wr_return_amt,
        sr.sr_return_amt,
        (ss_agg.total_net_profit
         - COALESCE(cr.cr_return_amount, 0)
         - COALESCE(wr.wr_return_amt, 0)
         - COALESCE(sr.sr_return_amt, 0)) AS net_after_returns
    FROM store_sales_agg ss_agg
    JOIN date_dim d_sales
        ON ss_agg.ss_sold_date_sk = d_sales.d_date_sk
    JOIN time_dim t_sales
        ON ss_agg.ss_sold_time_sk = t_sales.t_time_sk
    JOIN customer_demographics cd
        ON ss_agg.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ss_agg.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON ss_agg.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p
        ON ss_agg.ss_promo_sk = p.p_promo_sk
    -- store returns
    JOIN store_returns sr
        ON sr.sr_item_sk = ss_agg.ss_item_sk
        AND sr.sr_ticket_number = ss_agg.ss_ticket_number
    JOIN date_dim d_store_ret
        ON sr.sr_returned_date_sk = d_store_ret.d_date_sk
    JOIN time_dim t_store_ret
        ON sr.sr_return_time_sk = t_store_ret.t_time_sk
    JOIN reason r_sr
        ON sr.sr_reason_sk = r_sr.r_reason_sk
    -- catalog sales
    JOIN catalog_sales cs
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN date_dim d_cat_sales
        ON cs.cs_sold_date_sk = d_cat_sales.d_date_sk
    JOIN time_dim t_cat_sales
        ON cs.cs_sold_time_sk = t_cat_sales.t_time_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    -- catalog returns
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    JOIN date_dim d_cat_ret
        ON cr.cr_returned_date_sk = d_cat_ret.d_date_sk
    JOIN time_dim t_cat_ret
        ON cr.cr_returned_time_sk = t_cat_ret.t_time_sk
    JOIN reason r_cr
        ON cr.cr_reason_sk = r_cr.r_reason_sk
    -- web page (joined via creation date)
    JOIN web_page wp
        ON wp.wp_creation_date_sk = d_sales.d_date_sk
    -- web returns
    JOIN web_returns wr
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d_web_ret
        ON wr.wr_returned_date_sk = d_web_ret.d_date_sk
    JOIN time_dim t_web_ret
        ON wr.wr_returned_time_sk = t_web_ret.t_time_sk
    JOIN reason r_wr
        ON wr.wr_reason_sk = r_wr.r_reason_sk
    -- web site (opened on the same date as sales for simplicity)
    JOIN web_site ws
        ON ws.web_open_date_sk = d_sales.d_date_sk
    -- promotion start / end dates
    JOIN date_dim d_promo_start
        ON p.p_start_date_sk = d_promo_start.d_date_sk
    JOIN date_dim d_promo_end
        ON p.p_end_date_sk = d_promo_end.d_date_sk
    WHERE
        d_sales.d_year = 2000
        AND p.p_promo_name LIKE '%Discount%'
        AND ca.ca_state = 'CA'
        AND hd.hd_buy_potential = 'HIGH'
        AND sm.sm_type = 'AIR'
        AND r_sr.r_reason_desc = 'Damaged'
        AND d_promo_start.d_year BETWEEN 1999 AND 2001
),
agg_data AS (
    SELECT
        sales_year,
        p_promo_name,
        store_return_reason,
        ship_mode_type,
        ca_state,
        hd_buy_potential,
        cd_gender,
        SUM(total_net_paid) AS sum_total_net_paid,
        SUM(total_net_profit) AS sum_total_net_profit,
        SUM(cr_return_amount) AS sum_cr_return_amount,
        SUM(wr_return_amt) AS sum_wr_return_amt,
        SUM(sr_return_amt) AS sum_sr_return_amt,
        AVG(net_after_returns) AS avg_net_after_returns
    FROM joined_data
    GROUP BY
        sales_year,
        p_promo_name,
        store_return_reason,
        ship_mode_type,
        ca_state,
        hd_buy_potential,
        cd_gender
)
SELECT
    sales_year,
    p_promo_name,
    store_return_reason,
    ship_mode_type,
    ca_state,
    hd_buy_potential,
    cd_gender,
    sum_total_net_paid,
    sum_total_net_profit,
    sum_cr_return_amount,
    sum_wr_return_amt,
    sum_sr_return_amt,
    avg_net_after_returns,
    ROW_NUMBER() OVER (PARTITION BY sales_year ORDER BY avg_net_after_returns DESC) AS rn_year
FROM agg_data
ORDER BY avg_net_after_returns DESC
LIMIT 100

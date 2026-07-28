WITH
    -- Base store sales with related dimensions
    store_sales_enriched AS (
        SELECT
            ss.ss_sold_date_sk,
            ss.ss_sold_time_sk,
            ss.ss_ticket_number,
            ss.ss_item_sk,
            ss.ss_net_paid,
            ss.ss_net_paid_inc_tax,
            ss.ss_net_profit,
            ss.ss_quantity,
            cd.cd_demo_sk,
            cd.cd_gender,
            cd.cd_education_status,
            hd.hd_demo_sk,
            hd.hd_buy_potential,
            hd.hd_vehicle_count,
            hd.hd_income_band_sk,
            d_sales.d_date_sk,
            d_sales.d_year,
            d_sales.d_month_seq,
            d_sales.d_date,
            t_sales.t_time_sk,
            t_sales.t_hour
        FROM store_sales ss
        JOIN date_dim d_sales
          ON ss.ss_sold_date_sk = d_sales.d_date_sk
        JOIN time_dim t_sales
          ON ss.ss_sold_time_sk = t_sales.t_time_sk
        JOIN customer_demographics cd
          ON ss.ss_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd
          ON ss.ss_hdemo_sk = hd.hd_demo_sk
    ),
    
    -- Optional returns (left join to keep all sales rows)
    sales_with_returns AS (
        SELECT
            s.*,
            sr.sr_net_loss
        FROM store_sales_enriched s
        LEFT JOIN store_returns sr
          ON s.ss_ticket_number = sr.sr_ticket_number
         AND s.ss_item_sk = sr.sr_item_sk
    ),
    
    -- Income band (left join – some households may lack a band)
    sales_with_income AS (
        SELECT
            s.*, 
            ib.ib_lower_bound,
            ib.ib_upper_bound
        FROM sales_with_returns s
        LEFT JOIN income_band ib
          ON s.hd_income_band_sk = ib.ib_income_band_sk
    ),
    
    -- Web sales linked to the same date & time as the store sale (inner join keeps matching web activity)
    web_sales_enriched AS (
        SELECT
            ws.ws_sold_date_sk,
            ws.ws_sold_time_sk,
            ws.ws_web_page_sk,
            ws.ws_web_site_sk,
            ws.ws_net_paid,
            ws.ws_net_profit,
            wp.wp_type,
            wp.wp_autogen_flag,
            wsite.web_state
        FROM web_sales ws
        JOIN web_page wp
          ON ws.ws_web_page_sk = wp.wp_web_page_sk
        JOIN web_site wsite
          ON ws.ws_web_site_sk = wsite.web_site_sk
    ),
    
    -- Combine store and web information on matching date and time keys
    full_data AS (
        SELECT
            s.d_year,
            s.d_month_seq,
            s.cd_gender,
            s.cd_education_status,
            s.hd_buy_potential,
            s.hd_vehicle_count,
            s.ib_lower_bound,
            w.wp_type,
            w.wp_autogen_flag,
            w.web_state,
            SUM(s.ss_net_paid)               AS total_store_net_paid,
            SUM(w.ws_net_paid)               AS total_web_net_paid,
            COUNT(DISTINCT s.ss_ticket_number) AS store_ticket_cnt,
            AVG(s.sr_net_loss)               AS avg_return_loss,
            MAX(w.ws_net_profit)             AS max_web_profit,
            MIN(s.d_date)                    AS min_sales_date
        FROM sales_with_income s
        JOIN web_sales_enriched w
          ON s.ss_sold_date_sk = w.ws_sold_date_sk
         AND s.ss_sold_time_sk = w.ws_sold_time_sk
        WHERE
            s.d_year = 2001
            AND s.d_date = DATE '2001-03-15'
            AND s.t_hour BETWEEN 9 AND 17
            AND s.cd_gender = 'M'
            AND s.cd_education_status = 'College'
            AND s.hd_vehicle_count >= 2
            AND (s.ib_lower_bound IS NULL OR s.ib_lower_bound >= 50000)
            AND w.wp_type = 'order'
            AND w.wp_autogen_flag = 'N'
            AND w.web_state = 'CA'
        GROUP BY
            s.d_year,
            s.d_month_seq,
            s.cd_gender,
            s.cd_education_status,
            s.hd_buy_potential,
            s.hd_vehicle_count,
            s.ib_lower_bound,
            w.wp_type,
            w.wp_autogen_flag,
            w.web_state
    )
SELECT *
FROM full_data
LIMIT 100

WITH
    sales_base AS (
        SELECT
            ss.ss_sold_date_sk,
            ss.ss_ticket_number,
            ss.ss_quantity,
            ss.ss_sales_price,
            ss.ss_net_paid,
            ss.ss_net_profit,
            ss.ss_sold_time_sk,
            ss.ss_store_sk,
            ss.ss_promo_sk,
            ss.ss_cdemo_sk,
            ss.ss_hdemo_sk,
            ss.ss_addr_sk,
            td.t_hour,
            td.t_shift,
            s.s_store_id,
            s.s_state,
            s.s_gmt_offset,
            p.p_discount_active,
            p.p_promo_name,
            cd.cd_gender,
            cd.cd_education_status,
            hd.hd_vehicle_count,
            hd.hd_income_band_sk,
            ib.ib_upper_bound,
            ca.ca_country
        FROM tpcds.store_sales ss
        JOIN tpcds.time_dim td
            ON ss.ss_sold_time_sk = td.t_time_sk
        JOIN tpcds.store s
            ON ss.ss_store_sk = s.s_store_sk
        JOIN tpcds.promotion p
            ON ss.ss_promo_sk = p.p_promo_sk
        JOIN tpcds.customer_demographics cd
            ON ss.ss_cdemo_sk = cd.cd_demo_sk
        JOIN tpcds.household_demographics hd
            ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN tpcds.income_band ib
            ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN tpcds.customer_address ca
            ON ss.ss_addr_sk = ca.ca_address_sk
        WHERE
            s.s_state = 'CA'
            AND p.p_discount_active = 'Y'
            AND ib.ib_upper_bound >= 50000
            AND cd.cd_gender = 'F'
            AND ca.ca_country = 'United States'
            AND td.t_hour BETWEEN 9 AND 17
            AND hd.hd_vehicle_count >= 1
            AND s.s_rec_start_date > DATE '2000-01-01'
    ),
    returns_base AS (
        SELECT
            sr.sr_ticket_number,
            sr.sr_return_quantity,
            sr.sr_return_amt,
            sr.sr_fee,
            sr.sr_refunded_cash,
            sr.sr_reversed_charge,
            sr.sr_return_time_sk,
            sr.sr_store_sk,
            sr.sr_cdemo_sk,
            sr.sr_hdemo_sk,
            sr.sr_addr_sk
        FROM tpcds.store_returns sr
        WHERE sr.sr_return_amt > 100
    ),
    combined AS (
        SELECT
            sb.*, 
            rb.sr_return_quantity,
            rb.sr_return_amt,
            rb.sr_fee,
            rb.sr_refunded_cash,
            rb.sr_reversed_charge
        FROM sales_base sb
        FULL OUTER JOIN returns_base rb
            ON sb.ss_ticket_number = rb.sr_ticket_number
    ),
    aggregated AS (
        SELECT
            s_store_id,
            cd_gender,
            SUM(ss_quantity) AS total_quantity_sold,
            SUM(ss_sales_price) AS total_sales_amount,
            SUM(COALESCE(sr_return_amt, 0)) AS total_return_amount,
            AVG(ss_net_profit) AS avg_net_profit,
            COUNT(DISTINCT ss_ticket_number) AS distinct_tickets
        FROM combined
        GROUP BY GROUPING SETS (
            (s_store_id, cd_gender),
            (s_store_id),
            (cd_gender),
            ()
        )
    )
SELECT
    s_store_id,
    cd_gender,
    total_quantity_sold,
    total_sales_amount,
    total_return_amount,
    avg_net_profit,
    distinct_tickets,
    ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY total_sales_amount DESC) AS rn_sales_rank,
    (SELECT COUNT(*) FROM (SELECT ss_ticket_number FROM sales_base) EXCEPT SELECT sr_ticket_number FROM returns_base) AS tickets_without_return,
    (SELECT COUNT(*) FROM (SELECT ss_customer_sk FROM tpcds.store_sales) INTERSECT SELECT sr_customer_sk FROM tpcds.store_returns) AS customers_both_sales_and_returns
FROM aggregated
ORDER BY total_sales_amount DESC
LIMIT 100

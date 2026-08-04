WITH sampled_sales AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
),
customers_no_return AS (
    SELECT ss_customer_sk
    FROM sampled_sales
    GROUP BY ss_customer_sk
    EXCEPT
    SELECT cr_returning_customer_sk
    FROM catalog_returns
),
joined_data AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_cdemo_sk,
        ss.ss_hdemo_sk,
        ss.ss_addr_sk,
        ss.ss_promo_sk,
        ss.ss_customer_sk,
        ss.ss_ticket_number,
        ss.ss_net_paid,
        ss.ss_quantity,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_net_loss,
        d.d_year,
        d.d_month_seq,
        t.t_hour,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate,
        hd.hd_income_band_sk,
        ca.ca_state,
        p.p_cost,
        sm.sm_ship_mode_id,
        w.w_state,
        wp.wp_type,
        ws.web_name
    FROM sampled_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_returned_time_sk = t.t_time_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
    LEFT JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE ss.ss_customer_sk IN (SELECT ss_customer_sk FROM customers_no_return)
),
aggregated AS (
    SELECT
        d_year,
        cd_credit_rating,
        w_state,
        sm_ship_mode_id,
        SUM(ss_net_paid) AS total_net_paid,
        AVG(cr_return_amount) AS avg_return_amount,
        COUNT(DISTINCT ss_ticket_number) AS distinct_tickets
    FROM joined_data
    WHERE d_year = 2001
      AND t_hour BETWEEN 9 AND 17
      AND cd_credit_rating = 'Good'
      AND p_cost > 5000
      AND w_state = 'CA'
    GROUP BY d_year, cd_credit_rating, w_state, sm_ship_mode_id
)
SELECT
    d_year,
    cd_credit_rating,
    w_state,
    sm_ship_mode_id,
    total_net_paid,
    avg_return_amount,
    distinct_tickets,
    ROW_NUMBER() OVER (ORDER BY total_net_paid DESC) AS row_num
FROM aggregated
ORDER BY total_net_paid DESC
LIMIT 100

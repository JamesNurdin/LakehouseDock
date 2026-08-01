WITH base_data AS (
    SELECT
        d.d_year,
        d.d_date,
        cc.cc_state,
        cc.cc_name,
        p.p_promo_name,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        ca.ca_city,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        sr.sr_net_loss,
        cr.cr_net_loss,
        wr.wr_net_loss,
        (COALESCE(sr.sr_net_loss, 0) + COALESCE(cr.cr_net_loss, 0) + COALESCE(wr.wr_net_loss, 0)) AS total_net_loss,
        CASE 
            WHEN COALESCE(sr.sr_net_loss, 0) > 0 THEN 'Store Return Loss'
            WHEN COALESCE(cr.cr_net_loss, 0) > 0 THEN 'Catalog Return Loss'
            WHEN COALESCE(wr.wr_net_loss, 0) > 0 THEN 'Web Return Loss'
            ELSE 'No Loss'
        END AS loss_type
    FROM date_dim d
    JOIN store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN call_center cc
        ON p.p_start_date_sk = d.d_date_sk
        AND cc.cc_open_date_sk = d.d_date_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_returned_date_sk = d.d_date_sk
        AND sr.sr_customer_sk = c.c_customer_sk
        AND sr.sr_cdemo_sk = cd.cd_demo_sk
        AND sr.sr_addr_sk = ca.ca_address_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
        AND cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_refunded_customer_sk = c.c_customer_sk
        AND cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
        AND cr.cr_refunded_addr_sk = ca.ca_address_sk
        AND cr.cr_returning_customer_sk = c.c_customer_sk
        AND cr.cr_returning_cdemo_sk = cd.cd_demo_sk
        AND cr.cr_returning_addr_sk = ca.ca_address_sk
    LEFT JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_returning_customer_sk = c.c_customer_sk
        AND wr.wr_returning_cdemo_sk = cd.cd_demo_sk
        AND wr.wr_returning_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2000
      AND p.p_discount_active = 'Y'
      AND cc.cc_state = 'TX'
      AND ss.ss_quantity > 1
      AND p.p_promo_name IS NOT NULL
),
agg AS (
    SELECT
        d_year,
        cc_state,
        p_promo_name,
        SUM(total_net_loss) AS sum_total_net_loss,
        SUM(ss_ext_sales_price) AS sum_sales,
        COUNT(DISTINCT c_customer_id) AS unique_customers,
        CASE WHEN SUM(total_net_loss) > 0 THEN 'Net Loss' ELSE 'Net Gain' END AS net_status,
        (SELECT AVG(bd2.ss_ext_sales_price)
           FROM base_data bd2
          WHERE bd2.d_year = d_year) AS avg_sales_year
    FROM base_data
    GROUP BY ROLLUP (d_year, cc_state, p_promo_name)
)
SELECT
    d_year,
    cc_state,
    p_promo_name,
    sum_total_net_loss,
    sum_sales,
    unique_customers,
    net_status,
    avg_sales_year,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY sum_total_net_loss DESC) AS loss_rank
FROM agg
ORDER BY d_year, loss_rank
LIMIT 100

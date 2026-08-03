WITH joined_data AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_net_paid,
        ss.ss_ext_tax,
        ss.ss_sold_date_sk,
        ss.ss_quantity,
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        p.p_end_date_sk,
        d.d_year,
        cc.cc_call_center_id,
        wp.wp_url
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
        AND wp.wp_creation_date_sk = d.d_date_sk
),
aggregated AS (
    SELECT
        jd.c_customer_sk,
        jd.c_first_name,
        jd.c_last_name,
        jd.d_year,
        SUM(jd.ss_net_paid) AS total_net_paid
    FROM joined_data jd
    WHERE jd.p_end_date_sk IN (2450640, 2450592)
      AND jd.cd_gender = 'M'
      AND jd.ib_lower_bound >= 30000
      AND jd.ss_ext_tax > 10
      AND jd.d_year = 2002
      AND jd.ss_ticket_number NOT IN (
          SELECT sr_ticket_number
          FROM store_returns
          WHERE sr_refunded_cash > 0
      )
    GROUP BY jd.c_customer_sk, jd.c_first_name, jd.c_last_name, jd.d_year
),
aggregated2 AS (
    SELECT
        jd.c_customer_sk,
        jd.c_first_name,
        jd.c_last_name,
        jd.d_year,
        SUM(jd.ss_net_paid) AS total_net_paid
    FROM joined_data jd
    WHERE jd.p_end_date_sk IN (2450592)
      AND jd.cd_gender = 'F'
      AND jd.ib_lower_bound >= 30000
      AND jd.ss_ext_tax > 5
      AND jd.d_year = 2001
    GROUP BY jd.c_customer_sk, jd.c_first_name, jd.c_last_name, jd.d_year
),
intersect_customers AS (
    SELECT jd.c_customer_sk FROM joined_data jd WHERE jd.ib_lower_bound >= 40000
    INTERSECT
    SELECT jd.c_customer_sk FROM joined_data jd WHERE jd.cd_gender = 'F'
),
final_set AS (
    SELECT *
    FROM aggregated agg
    WHERE agg.c_customer_sk IN (SELECT c_customer_sk FROM intersect_customers)
)
SELECT
    c_customer_sk,
    c_first_name,
    c_last_name,
    d_year,
    total_net_paid,
    RANK() OVER (PARTITION BY d_year ORDER BY total_net_paid DESC) AS yearly_rank
FROM final_set
UNION
SELECT
    c_customer_sk,
    c_first_name,
    c_last_name,
    d_year,
    total_net_paid,
    RANK() OVER (PARTITION BY d_year ORDER BY total_net_paid DESC) AS yearly_rank
FROM aggregated2 agg2
WHERE agg2.c_customer_sk NOT IN (SELECT c_customer_sk FROM final_set)
ORDER BY yearly_rank, total_net_paid DESC
OFFSET 0 LIMIT 100

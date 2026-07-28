WITH filtered_data AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_buy_potential,
        wp.wp_url,
        wp.wp_link_count,
        wp.wp_rec_end_date
    FROM web_page wp
    JOIN customer c ON wp.wp_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE wp.wp_rec_end_date >= DATE '2000-01-01'
      AND wp.wp_rec_end_date <= DATE '2001-12-31'
      AND wp.wp_link_count >= 10
      AND hd.hd_buy_potential IN ('5001-10000', '>10000')
      AND ca.ca_state = 'CA'
      AND cd.cd_gender = 'M'
)
SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    ca_city,
    ca_state,
    cd_gender,
    cd_marital_status,
    hd_buy_potential,
    wp_url,
    wp_link_count,
    wp_rec_end_date,
    ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY wp_link_count DESC) AS rn_state,
    RANK() OVER (ORDER BY wp_link_count DESC) AS overall_rank
FROM filtered_data
ORDER BY rn_state, overall_rank
LIMIT 100

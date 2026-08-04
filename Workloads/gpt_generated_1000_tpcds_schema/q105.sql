WITH sub1 AS (
    SELECT
        c.c_customer_sk,
        SUM(cr.cr_net_loss) AS total_loss
    FROM catalog_returns cr
    JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN time_dim t1
        ON cr.cr_returned_time_sk = t1.t_time_sk
    JOIN store_returns sr
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN time_dim t2
        ON sr.sr_return_time_sk = t2.t_time_sk
    JOIN web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    WHERE ca.ca_county = 'Washington County'
      AND c.c_birth_country = 'SWITZERLAND'
      AND cd.cd_dep_college_count >= 3
      AND t1.t_sub_shift = 'morning'
      AND wp.wp_autogen_flag = 'Y'
    GROUP BY c.c_customer_sk
),
sub2 AS (
    SELECT
        c.c_customer_sk,
        SUM(cr.cr_net_loss) AS total_loss
    FROM catalog_returns cr
    JOIN customer c
        ON cr.cr_returning_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON cr.cr_returning_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
        ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN time_dim t1
        ON cr.cr_returned_time_sk = t1.t_time_sk
    JOIN store_returns sr
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN time_dim t2
        ON sr.sr_return_time_sk = t2.t_time_sk
    JOIN web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    WHERE ca.ca_county = 'Taos County'
      AND c.c_birth_country = 'KOREA'
      AND cd.cd_dep_employed_count = 2
      AND t1.t_sub_shift = 'afternoon'
      AND wp.wp_image_count > 3
    GROUP BY c.c_customer_sk
)
SELECT c_customer_sk, total_loss
FROM sub1
INTERSECT
SELECT c_customer_sk, total_loss
FROM sub2
ORDER BY c_customer_sk
LIMIT 100

WITH base_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        r.r_reason_desc,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        CASE
            WHEN SUM(sr.sr_net_loss) > 1000 THEN 'High'
            WHEN SUM(sr.sr_net_loss) > 500  THEN 'Medium'
            ELSE 'Low'
        END AS loss_category
    FROM store_returns sr
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd_cur
        ON c.c_current_cdemo_sk = cd_cur.cd_demo_sk
    JOIN customer_address ca_cur
        ON c.c_current_addr_sk = ca_cur.ca_address_sk
    WHERE s.s_manager = 'Franklin Mcclure'
      AND s.s_state = 'CA'
      AND r.r_reason_desc LIKE '%purchase%'
      AND sr.sr_return_quantity BETWEEN 20 AND 100
      AND EXISTS (
          SELECT 1
          FROM web_page wp
          WHERE wp.wp_customer_sk = c.c_customer_sk
            AND wp.wp_type = 'product'
            AND wp.wp_rec_start_date >= DATE '2023-01-01'
      )
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        r.r_reason_desc
),
agg_by_category AS (
    SELECT
        loss_category,
        AVG(total_net_loss) AS avg_loss,
        SUM(return_cnt) AS total_returns
    FROM base_agg
    GROUP BY loss_category
    HAVING AVG(total_net_loss) > 200
)
SELECT
    loss_category,
    avg_loss,
    total_returns
FROM agg_by_category
ORDER BY avg_loss DESC
LIMIT 100

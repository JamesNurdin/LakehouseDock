WITH sr_agg AS (
    SELECT
        sr.sr_store_sk,
        SUM(sr.sr_return_amt) AS total_return_amt,
        COUNT(*)          AS return_cnt
    FROM store_returns sr
    TABLESAMPLE BERNOULLI (10)   -- sample 10% of rows
    GROUP BY sr.sr_store_sk
)
SELECT
    d.d_year,
    s.s_store_name,
    i.i_category,
    cp.cp_department,
    ws.web_name,
    CASE WHEN sr_agg.total_return_amt > 1000 THEN 'HIGH' ELSE 'LOW' END AS return_level,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_name ORDER BY sr_agg.total_return_amt DESC) AS rn,
    t.t_hour,
    ca.ca_city,
    cd.cd_gender,
    elem AS name_char
FROM store s
FULL OUTER JOIN sr_agg
    ON s.s_store_sk = sr_agg.sr_store_sk
LEFT JOIN store_returns sr
    ON s.s_store_sk = sr.sr_store_sk
LEFT JOIN date_dim d
    ON sr.sr_returned_date_sk = d.d_date_sk
LEFT JOIN time_dim t
    ON sr.sr_return_time_sk = t.t_time_sk
LEFT JOIN item i
    ON sr.sr_item_sk = i.i_item_sk
LEFT JOIN customer c
    ON sr.sr_customer_sk = c.c_customer_sk
LEFT JOIN customer_address ca
    ON sr.sr_addr_sk = ca.ca_address_sk
LEFT JOIN customer_demographics cd
    ON sr.sr_cdemo_sk = cd.cd_demo_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_item_sk = i.i_item_sk
   AND cr.cr_returned_date_sk = d.d_date_sk
LEFT JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
   AND wp.wp_creation_date_sk = d.d_date_sk
LEFT JOIN web_site ws
    ON ws.web_open_date_sk = d.d_date_sk
CROSS JOIN UNNEST(split(ws.web_name, '')) AS t(elem)
WHERE d.d_year BETWEEN 2000 AND 2002
  AND i.i_current_price > 50
  AND s.s_state = 'CA'
  AND ca.ca_state = 'CA'
  AND cd.cd_gender = 'M'
  AND cp.cp_type = 'CATALOG'
  AND ws.web_name LIKE '%Shop%'
ORDER BY d.d_year DESC, sr_agg.total_return_amt DESC
OFFSET 0 LIMIT 100

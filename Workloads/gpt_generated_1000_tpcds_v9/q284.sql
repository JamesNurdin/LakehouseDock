WITH returns_no_promo AS (
    SELECT
        s.s_store_name AS store_name,
        d.d_year AS return_year,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_return_quantity) AS total_return_qty
    FROM store_returns sr
    INNER JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    INNER JOIN store s ON sr.sr_store_sk = s.s_store_sk
    INNER JOIN item i ON sr.sr_item_sk = i.i_item_sk
    INNER JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2000
      AND s.s_state = 'CA'
      AND ca.ca_county = 'Madison County'
      AND NOT EXISTS (
          SELECT 1
          FROM promotion p
          WHERE p.p_item_sk = i.i_item_sk
            AND d.d_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
      )
    GROUP BY s.s_store_name, d.d_year
    HAVING SUM(sr.sr_return_amt) > 500
),
returns_with_promo AS (
    SELECT
        s.s_store_name AS store_name,
        d.d_year AS return_year,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_return_quantity) AS total_return_qty
    FROM store_returns sr
    INNER JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    INNER JOIN store s ON sr.sr_store_sk = s.s_store_sk
    INNER JOIN item i ON sr.sr_item_sk = i.i_item_sk
    INNER JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    INNER JOIN promotion p ON p.p_item_sk = i.i_item_sk
    WHERE d.d_year = 2000
      AND s.s_state = 'TX'
      AND cd.cd_gender = 'F'
      AND p.p_discount_active = 'Y'
      AND d.d_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
    GROUP BY s.s_store_name, d.d_year
    HAVING SUM(sr.sr_return_amt) > 500
)
SELECT
    combined.store_name,
    combined.return_year,
    combined.total_return_amt,
    combined.total_return_qty
FROM (
    SELECT * FROM returns_no_promo
    UNION ALL
    SELECT * FROM returns_with_promo
) AS combined
ORDER BY combined.total_return_amt DESC
LIMIT 100

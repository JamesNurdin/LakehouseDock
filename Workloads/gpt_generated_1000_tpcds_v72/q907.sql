WITH store_ret AS (
        SELECT d.d_year,
               r.r_reason_desc,
               SUM(sr.sr_return_amt) AS total_return_amt
        FROM store_returns sr
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        JOIN item i ON sr.sr_item_sk = i.i_item_sk
        WHERE i.i_brand_id IN (
                SELECT i2.i_brand_id
                FROM item i2
                WHERE i2.i_class = 'scanners'
              )
          AND d.d_year BETWEEN 2000 AND 2002
        GROUP BY d.d_year, r.r_reason_desc
    ),
    catalog_ret AS (
        SELECT d.d_year,
               r.r_reason_desc,
               SUM(cr.cr_return_amount) AS total_return_amt
        FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        JOIN item i ON cr.cr_item_sk = i.i_item_sk
        WHERE i.i_brand_id IN (
                SELECT i2.i_brand_id
                FROM item i2
                WHERE i2.i_class = 'scanners'
              )
          AND d.d_year BETWEEN 2000 AND 2002
        GROUP BY d.d_year, r.r_reason_desc
    )
SELECT combined.d_year,
       combined.r_reason_desc,
       combined.total_return_amt,
       combined.source
FROM (
        SELECT d_year,
               r_reason_desc,
               total_return_amt,
               'store'   AS source
        FROM store_ret
        UNION ALL
        SELECT d_year,
               r_reason_desc,
               total_return_amt,
               'catalog' AS source
        FROM catalog_ret
    ) combined
WHERE combined.total_return_amt > (
        SELECT AVG(t.total_return_amt)
        FROM (
                SELECT total_return_amt FROM store_ret
                UNION ALL
                SELECT total_return_amt FROM catalog_ret
            ) t
    )
ORDER BY combined.d_year,
         combined.total_return_amt DESC
LIMIT 100

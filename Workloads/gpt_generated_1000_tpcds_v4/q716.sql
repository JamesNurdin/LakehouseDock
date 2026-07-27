/* goal: Compare net profit from catalog sales and net loss from store returns per customer per month, limited to years 2000‑2002 and only for customers linked to promotions with purpose 'Unknown' or returns with a defect reason. */
SELECT DISTINCT
    q.year,
    q.month,
    q.customer_id,
    q.total_amount,
    q.source_type
FROM (
    /* Catalog sales side */
    SELECT
        d.d_year AS year,
        d.d_moy  AS month,
        c.c_customer_id AS customer_id,
        SUM(cs.cs_net_profit) AS total_amount,
        'catalog' AS source_type
    FROM catalog_sales cs
    JOIN date_dim d
      ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c
      ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    WHERE p.p_purpose = 'Unknown'
      AND d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, d.d_moy, c.c_customer_id

    UNION ALL

    /* Store returns side */
    SELECT
        d.d_year AS year,
        d.d_moy  AS month,
        c.c_customer_id AS customer_id,
        SUM(sr.sr_net_loss) AS total_amount,
        'store' AS source_type
    FROM store_returns sr
    JOIN date_dim d
      ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer c
      ON sr.sr_customer_sk = c.c_customer_sk
    WHERE EXISTS (
        SELECT 1
        FROM reason r
        WHERE r.r_reason_sk = sr.sr_reason_sk
          AND r.r_reason_desc LIKE '%defect%'
    )
      AND d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, d.d_moy, c.c_customer_id
) q
ORDER BY q.year, q.month, q.total_amount DESC
LIMIT 100

WITH max_discount AS (
    SELECT i.i_item_sk,
           MAX(cs.cs_ext_discount_amt) AS max_disc
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_item_sk
)
(
    SELECT d.d_year,
           s.s_store_name,
           SUM(ss.ss_net_paid) AS total_sales,
           MAX(md.max_disc) AS max_catalog_discount
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN max_discount md ON ss.ss_item_sk = md.i_item_sk
    WHERE s.s_market_desc LIKE '%patient%'
      AND EXISTS (
          SELECT 1
          FROM store_returns sr
          WHERE sr.sr_item_sk = ss.ss_item_sk
            AND sr.sr_ticket_number = ss.ss_ticket_number
            AND sr.sr_return_quantity > 0
      )
    GROUP BY d.d_year, s.s_store_name
)
UNION ALL
(
    SELECT d.d_year,
           p.p_promo_name,
           SUM(cs.cs_net_paid) AS total_sales,
           CAST(NULL AS decimal(7,2)) AS max_catalog_discount
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'Y'
    GROUP BY d.d_year, p.p_promo_name
)
LIMIT 100

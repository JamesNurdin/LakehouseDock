WITH inv_sample AS (
    SELECT inv_item_sk,
           inv_date_sk,
           inv_quantity_on_hand
    FROM inventory TABLESAMPLE BERNOULLI (10)
)
SELECT *
FROM (
    SELECT
        d.d_date                     AS sale_date,
        i.i_item_id                  AS item_id,
        ss.ss_net_paid               AS sale_amount,
        p.p_promo_name               AS promo_name,
        inv.inv_quantity_on_hand    AS quantity_on_hand
    FROM store_sales ss
    JOIN date_dim d
      ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i
      ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN promotion p
      ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN inv_sample inv
      ON ss.ss_item_sk = inv.inv_item_sk
     AND ss.ss_sold_date_sk = inv.inv_date_sk
    WHERE d.d_year = 2001
      AND ss.ss_ticket_number NOT IN (SELECT sr_ticket_number FROM store_returns)

    UNION

    SELECT
        d.d_date                     AS sale_date,
        i.i_item_id                  AS item_id,
        cs.cs_net_paid               AS sale_amount,
        p.p_promo_name               AS promo_name,
        inv.inv_quantity_on_hand    AS quantity_on_hand
    FROM catalog_sales cs
    JOIN date_dim d
      ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN inv_sample inv
      ON cs.cs_item_sk = inv.inv_item_sk
     AND cs.cs_sold_date_sk = inv.inv_date_sk
    WHERE d.d_year = 2001
      AND cs.cs_order_number NOT IN (SELECT sr_ticket_number FROM store_returns)
) AS combined
ORDER BY sale_amount DESC
OFFSET 20 ROWS
LIMIT 100

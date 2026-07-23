WITH item_sales AS (
    SELECT
        d.d_year,
        i.i_item_id,
        i.i_category,
        i.i_brand,
        SUM(ss.ss_net_paid) AS store_net_paid,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(ws.ws_net_paid) AS web_net_paid,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(sr.sr_net_loss) AS store_return_loss,
        SUM(cr.cr_net_loss) AS catalog_return_loss,
        SUM(inv.inv_quantity_on_hand) AS inventory_on_hand
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr
        ON sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_returned_date_sk = d.d_date_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_item_sk = i.i_item_sk
        AND cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d.d_date_sk
    LEFT JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND cd.cd_marital_status = 'M'
      AND p.p_purpose = 'Unknown'
      AND i.i_brand = 'Brand#13'
      AND EXISTS (
          SELECT 1
          FROM ship_mode sm
          WHERE sm.sm_ship_mode_sk = cr.cr_ship_mode_sk
            AND sm.sm_type = 'AIR'
      )
    GROUP BY d.d_year, i.i_item_id, i.i_category, i.i_brand
)
SELECT
    d_year,
    i_category,
    i_brand,
    COUNT(i_item_id) AS num_items,
    SUM(store_net_paid + web_net_paid) AS total_net_paid,
    AVG(store_net_profit + web_net_profit - store_return_loss - catalog_return_loss) AS avg_net_profit_per_item,
    SUM(inventory_on_hand) AS total_inventory_on_hand
FROM item_sales
WHERE inventory_on_hand > 0
GROUP BY d_year, i_category, i_brand
HAVING COUNT(i_item_id) >= 5
ORDER BY total_net_paid DESC
LIMIT 100

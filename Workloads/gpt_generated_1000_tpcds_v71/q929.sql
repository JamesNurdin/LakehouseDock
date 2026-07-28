/*
  Goal: Rank items of brand 'Brand#45' for the year 2000 by their combined net contribution from catalog returns, store returns, and web sales, 
  show whether the catalog loss for the item is above or below the yearly average loss, and include the web site name (if any).
*/
WITH filtered AS (
    SELECT
        cr.cr_item_sk,
        cr.cr_net_loss AS cr_net_loss,
        sr.sr_net_loss AS sr_net_loss,
        ws.ws_net_profit AS ws_net_profit,
        ws.ws_web_site_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_brand,
        i.i_category,
        d.d_year,
        r.r_reason_desc,
        ws_site.web_name
    FROM catalog_returns cr
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
        AND sr.sr_returned_date_sk = d.d_date_sk
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN web_site ws_site
        ON ws.ws_web_site_sk = ws_site.web_site_sk
    WHERE d.d_year = 2000
      AND i.i_brand = 'Brand#45'
      AND cd.cd_education_status = 'College'
)
SELECT
    i_item_id,
    i_product_name,
    r_reason_desc,
    SUM(cr_net_loss)                         AS total_catalog_net_loss,
    SUM(sr_net_loss)                         AS total_store_net_loss,
    SUM(ws_net_profit)                       AS total_web_profit,
    SUM(cr_net_loss + sr_net_loss + ws_net_profit) AS total_contribution,
    RANK() OVER (ORDER BY SUM(cr_net_loss + sr_net_loss + ws_net_profit) DESC) AS profit_rank,
    CASE
        WHEN SUM(cr_net_loss) > (
                SELECT AVG(cr2.cr_net_loss)
                FROM catalog_returns cr2
                JOIN date_dim d2 ON cr2.cr_returned_date_sk = d2.d_date_sk
                WHERE d2.d_year = 2000
            )
        THEN 'Above Avg Loss'
        ELSE 'Below Avg Loss'
    END AS loss_category,
    web_name
FROM filtered
GROUP BY
    i_item_id,
    i_product_name,
    r_reason_desc,
    web_name
ORDER BY profit_rank, i_item_id
LIMIT 100

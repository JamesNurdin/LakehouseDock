WITH sampled_inventory AS (
    SELECT *
    FROM inventory TABLESAMPLE BERNOULLI (10)
),
joined AS (
    SELECT
        i.i_brand AS i_brand,
        i.i_category AS i_category,
        d.d_year AS d_year,
        cr.cr_net_loss,
        sr.sr_net_loss,
        wr.wr_net_loss,
        p.p_channel_catalog,
        cd.cd_gender
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    JOIN catalog_returns cr
        ON cr.cr_item_sk = i.i_item_sk
        AND cr.cr_returned_date_sk = d.d_date_sk
    JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN sampled_inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1998 AND 2000
      AND i.i_brand = 'Brand#32'
      AND p.p_channel_catalog = 'N'
      AND cd.cd_gender = 'M'
),
aggregated AS (
    SELECT
        i_brand AS brand,
        i_category AS category,
        d_year AS year,
        SUM(cr_net_loss) AS total_catalog_loss,
        SUM(sr_net_loss) AS total_store_loss,
        SUM(wr_net_loss) AS total_web_loss,
        SUM(cr_net_loss + sr_net_loss + wr_net_loss) AS total_loss
    FROM joined
    GROUP BY ROLLUP (i_brand, d_year, i_category)
)
SELECT
    brand,
    year,
    category,
    total_catalog_loss,
    total_store_loss,
    total_web_loss,
    total_loss,
    RANK() OVER (PARTITION BY category ORDER BY total_loss DESC) AS loss_rank_in_category
FROM aggregated
ORDER BY total_loss DESC
LIMIT 100

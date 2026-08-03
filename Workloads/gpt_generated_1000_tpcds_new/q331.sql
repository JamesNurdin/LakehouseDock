WITH sales_base AS (
    SELECT
        s.s_store_id,
        d.d_year,
        p.p_channel_catalog,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(cr.cr_net_loss) AS total_cr_net_loss,
        SUM(wr.wr_net_loss) AS total_wr_net_loss
    FROM store_sales ss
    JOIN date_dim d               ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t               ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i                   ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca      ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s                  ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p              ON ss.ss_promo_sk = p.p_promo_sk
    JOIN catalog_returns cr      ON cr.cr_item_sk = i.i_item_sk
                                   AND cr.cr_returned_date_sk = d.d_date_sk
    JOIN warehouse w             ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r1                ON cr.cr_reason_sk = r1.r_reason_sk
    JOIN web_returns wr          ON wr.wr_item_sk = i.i_item_sk
                                   AND wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r2                ON wr.wr_reason_sk = r2.r_reason_sk
    WHERE d.d_year = 2001                     -- predicate #1
      AND p.p_channel_catalog = 'Y'           -- predicate #2
      AND ca.ca_state = 'CA'                  -- predicate #3
      AND t.t_hour BETWEEN 9 AND 17           -- predicate #4
      AND i.i_brand_id IN (100, 200)          -- predicate #5
    GROUP BY s.s_store_id, d.d_year, p.p_channel_catalog
),

avg_store_loss AS (
    SELECT s_store_id,
           AVG(total_cr_net_loss + total_wr_net_loss) AS avg_total_loss
    FROM sales_base
    GROUP BY s_store_id
),

high_loss_stores AS (
    SELECT s_store_id
    FROM avg_store_loss
    WHERE avg_total_loss > 5000
)

SELECT *
FROM (
    SELECT s_store_id, total_net_profit, total_cr_net_loss, total_wr_net_loss
    FROM sales_base
    WHERE p_channel_catalog = 'Y'
    UNION
    SELECT s_store_id, total_net_profit, total_cr_net_loss, total_wr_net_loss
    FROM sales_base
    WHERE p_channel_catalog = 'N'
) AS u
WHERE u.s_store_id NOT IN (SELECT s_store_id FROM high_loss_stores)
  AND u.total_net_profit > (
        SELECT AVG(ss_net_paid)
        FROM store_sales ss
        WHERE ss.ss_sold_date_sk = (
              SELECT d_date_sk
              FROM date_dim
              WHERE d_date = DATE '2001-01-01'
        )
      )
EXCEPT
SELECT s.s_store_id, 0, 0, 0
FROM store s
WHERE s.s_store_name LIKE 'Test%'
LIMIT 100

WITH per_group AS (
    SELECT
        s.s_store_id,
        d.d_year,
        i.i_brand,
        SUM(sr.sr_net_loss) AS store_net_loss,
        SUM(cr.cr_net_loss) AS catalog_net_loss,
        SUM(wr.wr_net_loss) AS web_net_loss,
        SUM(sr.sr_return_quantity) AS store_return_qty,
        SUM(cr.cr_return_quantity) AS catalog_return_qty,
        SUM(wr.wr_return_quantity) AS web_return_qty
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_item_sk = i.i_item_sk
        AND cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = i.i_item_sk
        AND wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND t.t_hour BETWEEN 8 AND 16
      AND i.i_brand = 'Brand#12'
      AND hd.hd_dep_count > 2
      AND ib.ib_lower_bound >= 20000
    GROUP BY s.s_store_id, d.d_year, i.i_brand
)
SELECT
    brand,
    AVG(total_net_loss) AS avg_total_net_loss,
    SUM(total_return_qty) AS sum_return_qty
FROM (
    SELECT
        i_brand AS brand,
        (store_net_loss + catalog_net_loss + web_net_loss) AS total_net_loss,
        (store_return_qty + catalog_return_qty + web_return_qty) AS total_return_qty
    FROM per_group
) agg
GROUP BY brand
HAVING SUM(total_return_qty) > 100
ORDER BY avg_total_net_loss DESC
LIMIT 10

WITH avg_daily_profit AS (
        SELECT ss_sold_date_sk AS d_date_sk,
               AVG(ss_net_profit) AS avg_profit
        FROM store_sales
        GROUP BY ss_sold_date_sk
    )
SELECT
        s.s_store_name,
        d.d_date,
        i.i_product_name,
        p.p_promo_name,
        cr.cr_return_amount,
        wr.wr_return_amt,
        inv.inv_quantity_on_hand,
        ss.ss_net_paid,
        ss.ss_net_profit,
        RANK() OVER (PARTITION BY d.d_year ORDER BY ss.ss_net_profit DESC) AS profit_rank_year,
        CASE
            WHEN ss.ss_net_profit > (
                    SELECT adp.avg_profit
                    FROM avg_daily_profit adp
                    WHERE adp.d_date_sk = d.d_date_sk
                ) THEN 'Above Avg'
            ELSE 'Below Avg'
        END AS profit_vs_avg
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
                         AND cr.cr_returned_date_sk = d.d_date_sk
JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
                     AND wr.wr_returned_date_sk = d.d_date_sk
JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
                    AND inv.inv_date_sk = d.d_date_sk
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE s.s_manager IN ('Matt Frederick', 'Leroy Walker')
  AND d.d_year = 2001
  AND i.i_category = 'Electronics'
  AND p.p_discount_active = 'Y'
  AND ca.ca_state = 'CA'
  AND t.t_hour BETWEEN 8 AND 17
ORDER BY profit_rank_year, s.s_store_name
LIMIT 100

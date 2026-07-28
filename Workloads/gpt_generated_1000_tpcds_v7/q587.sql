WITH sales_all AS (
    SELECT
        cs.cs_bill_customer_sk       AS customer_sk,
        cs.cs_net_profit             AS cs_net_profit,
        ws.ws_net_profit             AS ws_net_profit,
        cs.cs_ext_tax                AS cs_ext_tax,
        cs.cs_list_price             AS cs_list_price,
        i.i_current_price            AS item_current_price,
        p.p_channel_catalog          AS promo_channel_catalog,
        hd.hd_dep_count              AS dep_count,
        ib.ib_upper_bound            AS income_upper_bound,
        cr.cr_return_amount          AS return_amount,
        r.r_reason_desc              AS return_reason_desc,
        inv.inv_quantity_on_hand     AS inventory_on_hand,
        wsite.web_name               AS web_site_name
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
    LEFT JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN web_sales ws
        ON i.i_item_sk = ws.ws_item_sk
    JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN inventory inv
        ON i.i_item_sk = inv.inv_item_sk
    WHERE cs.cs_ext_tax > 20
      AND cs.cs_list_price > 100
      AND i.i_current_price BETWEEN 10 AND 100
      AND p.p_channel_catalog = 'N'
      AND hd.hd_dep_count >= 2
      AND ib.ib_upper_bound < 120000
      AND (cr.cr_return_amount IS NULL OR cr.cr_return_amount > 0)
)
SELECT
    customer_sk,
    SUM(cs_net_profit) + SUM(ws_net_profit) AS total_net_profit,
    COUNT(*)                           AS txn_count,
    RANK() OVER (ORDER BY SUM(cs_net_profit) + SUM(ws_net_profit) DESC) AS profit_rank
FROM sales_all
GROUP BY customer_sk
HAVING SUM(cs_net_profit) + SUM(ws_net_profit) > 5000
ORDER BY profit_rank
LIMIT 20

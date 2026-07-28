WITH agg AS (
    SELECT
        d.d_year,
        i.i_category,
        cd.cd_gender,
        hd.hd_buy_potential,
        COUNT(DISTINCT ws.ws_order_number) AS orders,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t
        ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
        AND inv.inv_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
      AND t.t_shift = 'first'
      AND ib.ib_lower_bound >= 50001
    GROUP BY d.d_year, i.i_category, cd.cd_gender, hd.hd_buy_potential
    HAVING SUM(ws.ws_net_profit) > 10000
)
SELECT
    agg.d_year,
    agg.i_category,
    agg.cd_gender,
    agg.hd_buy_potential,
    agg.orders,
    agg.total_profit,
    AVG(agg.total_profit) OVER (
        PARTITION BY agg.d_year
        ORDER BY agg.i_category
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_avg_profit
FROM agg
ORDER BY agg.d_year DESC, agg.total_profit DESC
LIMIT 100

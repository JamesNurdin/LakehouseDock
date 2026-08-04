WITH sampled_ws AS (
    SELECT *
    FROM web_sales
    TABLESAMPLE BERNOULLI (10)
),
joined AS (
    SELECT
        ws.ws_sold_date_sk,
        d.d_year,
        ws.ws_item_sk,
        i.i_product_name,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_net_profit,
        ws.ws_order_number,
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_state,
        ca.ca_country,
        cd.cd_gender,
        hd.hd_buy_potential,
        ib.ib_lower_bound,
        p.p_promo_name,
        ARRAY[ws.ws_quantity, ws.ws_quantity * 2] AS qty_array,
        ss.ss_sold_date_sk AS ss_sold_date_sk,
        wr.wr_reason_sk,
        r.r_reason_desc,
        inv.inv_quantity_on_hand,
        wsite.web_site_id
    FROM sampled_ws ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    LEFT JOIN store_sales ss ON ss.ss_item_sk = ws.ws_item_sk AND ss.ss_sold_date_sk = ws.ws_sold_date_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    LEFT JOIN inventory inv ON inv.inv_item_sk = ws.ws_item_sk AND inv.inv_date_sk = ws.ws_sold_date_sk
)
SELECT
    d_year,
    i_product_name,
    ca_state,
    cd_gender,
    hd_buy_potential,
    SUM(ws_net_paid) AS total_net_paid,
    AVG(ws_net_profit) AS avg_net_profit,
    COUNT(DISTINCT ws_order_number) AS order_cnt,
    MIN(ws_quantity) AS min_qty,
    MAX(ws_quantity) AS max_qty,
    SUM(qty) AS total_qty_unnested
FROM joined
CROSS JOIN UNNEST(qty_array) AS t(qty)
WHERE d_year = 2001
  AND ib_lower_bound >= 50000
  AND ca_country = 'United States'
  AND EXISTS (
        SELECT 1
        FROM store_sales ss2
        WHERE ss2.ss_item_sk = joined.ws_item_sk
          AND ss2.ss_net_paid > 1000
    )
GROUP BY d_year, i_product_name, ca_state, cd_gender, hd_buy_potential
HAVING SUM(ws_net_paid) > 10000
ORDER BY total_net_paid DESC
OFFSET 0 FETCH NEXT 100 ROWS ONLY

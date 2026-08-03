/* goal: Identify top‑selling items by net profit during morning shifts, segmented by promotion cost tier and enriched with word tokens from the item identifiers, while ranking and cumulatively aggregating profits across hours. */
WITH sales_agg AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        i.i_item_id,
        i.i_product_name,
        td.t_hour,
        ws.ws_net_profit,
        p.p_cost,
        p.p_discount_active,
        CASE WHEN p.p_cost > 500 THEN 'High' ELSE 'Low' END AS promo_cost_category,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        wsit.web_gmt_offset,
        ARRAY[ i.i_item_id, i.i_category ] AS item_array
    FROM web_sales ws
    JOIN time_dim td
        ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN web_site wsit
        ON ws.ws_web_site_sk = wsit.web_site_sk
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN catalog_sales cs
        ON cs.cs_item_sk = i.i_item_sk
    JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_returned_time_sk = td.t_time_sk
        AND wr.wr_reason_sk = r.r_reason_sk
    WHERE td.t_sub_shift = 'morning'
      AND wsit.web_gmt_offset = -5.00
      AND ib.ib_upper_bound <= 80000
      AND p.p_cost BETWEEN 500 AND 2000
)
SELECT
    sa.ws_order_number,
    sa.i_item_id,
    sa.i_product_name,
    sa.t_hour,
    sa.ws_net_profit,
    sa.promo_cost_category,
    word AS item_word,
    RANK() OVER (PARTITION BY sa.t_hour ORDER BY sa.ws_net_profit DESC) AS profit_rank,
    SUM(sa.ws_net_profit) OVER (
        PARTITION BY sa.i_item_id
        ORDER BY sa.t_hour
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cum_profit
FROM sales_agg sa
CROSS JOIN UNNEST(sa.item_array) AS t(word)
WHERE sa.ws_net_profit IS NOT NULL
ORDER BY sa.ws_net_profit DESC
OFFSET 0 FETCH NEXT 100 ROWS ONLY

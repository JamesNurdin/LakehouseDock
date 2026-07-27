WITH catalog_fact AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_net_profit,
        i.i_item_id,
        i.i_manufact,
        i.i_color,
        d.d_year,
        d.d_month_seq,
        ca.ca_city,
        cd.cd_gender,
        hd.hd_buy_potential
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2002
      AND i.i_color IN ('red', 'royal')
      AND hd.hd_buy_potential = '1001-5000'
      AND ca.ca_city = 'Smith'
      AND cd.cd_gender = 'M'
      AND cp.cp_type = 'promo'
),
store_fact AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_net_profit,
        i.i_item_id,
        i.i_manufact,
        i.i_color,
        d.d_year,
        d.d_month_seq,
        ca.ca_city,
        cd.cd_gender,
        hd.hd_buy_potential
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2002
      AND i.i_color IN ('red', 'royal')
      AND hd.hd_buy_potential = '1001-5000'
      AND ca.ca_city = 'Smith'
      AND cd.cd_gender = 'M'
      AND ss.ss_quantity > 1
),
web_ret_fact AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_item_sk,
        wr.wr_net_loss,
        i.i_item_id,
        i.i_manufact,
        i.i_color,
        d.d_year,
        d.d_month_seq,
        ca.ca_city,
        cd.cd_gender,
        hd.hd_buy_potential
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2002
      AND i.i_color IN ('red', 'royal')
      AND hd.hd_buy_potential = '1001-5000'
      AND ca.ca_city = 'Smith'
      AND cd.cd_gender = 'M'
      AND wr.wr_return_quantity > 0
),
combined AS (
    SELECT i_item_id, i_manufact, i_color, cs_net_profit AS net_profit, ca_city FROM catalog_fact
    UNION ALL
    SELECT i_item_id, i_manufact, i_color, ss_net_profit AS net_profit, ca_city FROM store_fact
    UNION ALL
    SELECT i_item_id, i_manufact, i_color, -wr_net_loss AS net_profit, ca_city FROM web_ret_fact
),
agg AS (
    SELECT
        i_item_id,
        i_manufact,
        i_color,
        SUM(net_profit) AS total_net_profit,
        COUNT(DISTINCT ca_city) AS distinct_cities
    FROM combined
    GROUP BY i_item_id, i_manufact, i_color
)
SELECT
    item_id,
    manufact,
    color,
    total_net_profit,
    profit_rank,
    distinct_cities
FROM (
    SELECT
        i_item_id AS item_id,
        i_manufact AS manufact,
        i_color AS color,
        total_net_profit,
        RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank,
        distinct_cities
    FROM agg
) q
WHERE profit_rank <= 10
ORDER BY total_net_profit DESC
LIMIT 100
